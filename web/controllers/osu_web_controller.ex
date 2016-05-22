defmodule Trucksu.OsuWebController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    OsuBeatmapsetFetcher,
    Session,

    Friendship,
    OsuBeatmap,
    OsuBeatmapset,
    Score,
  }

  @ranked_status_not_submitted -1
  @ranked_status_up_to_date 2
  @ranked_status_update_available 1

  @everything_is_ranked true

  plug :authenticate when action in [:get_scores, :search_set]
  # TODO: Uncomment when rate limiting is implemented
  plug :fetch_osu_beatmap when action == :get_scores

  defp authenticate(conn, _) do
    username = conn.params["us"] || conn.params["u"]
    password_md5 = conn.params["ha"] || conn.params["h"]
    case Session.authenticate(username, password_md5, true) do
      {:error, reason} ->
        Logger.warn "#{username} attempted to get scores, but was unable to authenticate: #{reason}"
        stop_plug(conn, 403)
      {:ok, user} ->
        assign(conn, :user, user)
    end
  end

  defp find_beatmap_with_filename_in_set(osu_beatmapset, filename) do
    Logger.debug "Checking if same difficulty exists in freshly fetched set"

    Enum.find(osu_beatmapset.beatmaps, fn(osu_beatmap) ->
      version = osu_beatmap.version
      # osu! doesn't include colons in filename difficulty
      # TODO: Find what other characters osu! strips out from the filename
      version = String.replace(version, ":", "")
      Logger.debug "comparing '#{filename}' and #{version}"
      case Regex.named_captures(~r/ \[(?<version>.*)\]\.osu$/, filename) do
        %{"version" => ^version} ->
          true

        _ ->
          false
      end
    end)
  end

  defp fetch_osu_beatmap(%Plug.Conn{params: %{"f" => filename, "c" => file_md5, "i" => beatmapset_id}} = conn, opts) do
    osu_beatmap = Repo.one from ob in OsuBeatmap,
      join: obs in assoc(ob, :beatmapset),
      where: ob.file_md5 == ^file_md5,
      preload: [beatmapset: obs]
    case osu_beatmap do
      nil ->
        # Check the database then the API if necessary

        query = from obs in OsuBeatmapset,
          left_join: ob in assoc(obs, :beatmaps),
          where: obs.id == ^beatmapset_id,
          preload: [beatmaps: ob]
        case Repo.one query do
          nil ->
            # We don't have the beatmapset
            # Call osu! API
            if conn.assigns[:fetched_set] do
              conn
              |> assign(:beatmap_status, :not_submitted)
              |> assign(:osu_beatmap, nil)
            else
              if OsuBeatmapsetFetcher.fetch(beatmapset_id) do
                conn = assign(conn, :fetched_set, true)

                # recurse
                fetch_osu_beatmap(conn, opts)
              else
                # can't access osu! API
                conn
                |> assign(:beatmap_status, :not_submitted)
                |> assign(:osu_beatmap, nil)
              end
            end

          osu_beatmapset ->
            # We have some version of the beatmapset
            Logger.debug "We have some version of the beatmapset"

            cond do
              # 3 = qualified, 2 = approved, 1 = ranked, 0 = pending, -1 = WIP, -2 = graveyard
              osu_beatmapset.approved == 2 or osu_beatmapset.approved == 1 ->
                # approved or ranked, client version either needs to be updated or is not submitted
                osu_beatmap = find_beatmap_with_filename_in_set(osu_beatmapset, filename)
                case osu_beatmap do
                  nil ->
                    conn
                    |> assign(:beatmap_status, :not_submitted)
                    |> assign(:osu_beatmap, osu_beatmap)
                  _ ->
                    conn
                    |> assign(:beatmap_status, :update_available)
                    |> assign(:osu_beatmap, osu_beatmap)
                end
              true ->
                # not approved and not ranked, may need to hit the osu! API first

                if conn.assigns[:fetched_set] do
                  osu_beatmap = find_beatmap_with_filename_in_set(osu_beatmapset, filename)
                  case osu_beatmap do
                    nil ->
                      conn
                      |> assign(:beatmap_status, :not_submitted)
                      |> assign(:osu_beatmap, osu_beatmap)
                    _ ->
                      conn
                      |> assign(:beatmap_status, :update_available)
                      |> assign(:osu_beatmap, osu_beatmap)
                  end
                else
                  if OsuBeatmapsetFetcher.fetch(beatmapset_id) do
                    conn = assign(conn, :fetched_set, true)

                    # recurse
                    fetch_osu_beatmap(conn, opts)
                  else
                    # can't access osu! API
                    conn
                    |> assign(:beatmap_status, :not_submitted)
                    |> assign(:osu_beatmap, nil)
                  end
                end
            end
        end

      _ ->
        # TODO: handle osu_beatmap.beatmapset_id != beatmapset_id

        # Check the database then the API if not ranked
        cond do
          # 3 = qualified, 2 = approved, 1 = ranked, 0 = pending, -1 = WIP, -2 = graveyard
          osu_beatmap.beatmapset.approved == 2 or osu_beatmap.beatmapset.approved == 1 ->
            conn
            |> assign(:beatmap_status, :up_to_date)
            |> assign(:osu_beatmap, osu_beatmap)
          true ->
            # not approved and not ranked, need to hit the osu API first
            if conn.assigns[:fetched_set] do
              conn
              |> assign(:beatmap_status, :up_to_date)
              |> assign(:osu_beatmap, osu_beatmap)
            else
              if OsuBeatmapsetFetcher.fetch(beatmapset_id) do
                conn = assign(conn, :fetched_set, true)

                # recurse
                fetch_osu_beatmap(conn, opts)
              else
                # can't access osu! API
                conn
                |> assign(:beatmap_status, :not_submitted)
                |> assign(:osu_beatmap, osu_beatmap)
              end
            end
        end
    end
  end

  def get_scores(conn, %{"c" => _file_md5, "i" => _beatmapset_id, "f" => _filename, "m" => game_mode, "v" => type, "mods" => mods}) do

    %{
      user: user,
      beatmap_status: beatmap_status,
      osu_beatmap: osu_beatmap,
    } = conn.assigns

    data = case osu_beatmap do
      nil ->
        "-1|false"

      _ ->
        build_and_format_scores(user, osu_beatmap, beatmap_status, type, mods, game_mode)
    end

    render conn, "response.raw", data: data
  end

  def build_and_format_scores(user, osu_beatmap, beatmap_status, type, mods, game_mode) do

    # type
    # 4 - country ranking
    # 1 - global ranking
    # 2 - global ranking (selected mods)
    # 3 - friend ranking

    %OsuBeatmap{file_md5: file_md5} = osu_beatmap

    preload_query = case type do
      "2" ->
        # global ranking (selected mods)

        {mods, _} = Integer.parse(mods)

        from s in Score.completed,
          join: u in assoc(s, :user),
          where: u.banned == false
            and s.file_md5 == ^file_md5
            and s.game_mode == ^game_mode
            and s.mods == ^mods,
          order_by: [desc: s.score],
          preload: [user: u]

      "3" ->
        # friend ranking

        user_id = user.id
        from s in Score.completed,
          join: f in Friendship,
          on: (f.requester_id == ^user_id
            and s.user_id == f.receiver_id)
            or s.user_id == ^user_id,
          join: u in assoc(s, :user),
          where: u.banned == false
            and s.file_md5 == ^file_md5
            and s.game_mode == ^game_mode,
          order_by: [desc: s.score],
          preload: [user: u]

      "4" ->
        # country ranking

        country = user.country
        from s in Score.completed,
          join: u in assoc(s, :user),
          where: u.banned == false
            and s.file_md5 == ^file_md5
            and s.game_mode == ^game_mode
            and u.country == ^country,
          order_by: [desc: s.score],
          preload: [user: u]

      _ ->
        from s in Score.completed,
          join: u in assoc(s, :user),
          where: u.banned == false
            and s.file_md5 == ^file_md5
            and s.game_mode == ^game_mode,
          order_by: [desc: s.score],
          preload: [user: u]
    end

    osu_beatmap = Repo.preload osu_beatmap, scores: preload_query

    # TODO: Filter in SQL with subquery
    scores = Enum.uniq_by(osu_beatmap.scores, &(&1.user_id))

    osu_beatmap = %{osu_beatmap | scores: scores}

    ranked_status = case beatmap_status do
      :not_submitted -> raise "attempting to format an unsubmitted beatmap"
      :up_to_date -> @ranked_status_up_to_date
      :update_available -> @ranked_status_update_available
      _ -> 2
    end

    format_beatmap(ranked_status, osu_beatmap, user.username, game_mode)
  end

  defp format_direct(osu_beatmap) do
    "#{osu_beatmap.beatmapset_id}.osz|#{osu_beatmap.beatmapset.artist}|#{osu_beatmap.beatmapset.title}|#{osu_beatmap.beatmapset.creator}|#{osu_beatmap.approved}|10.00000|1|#{osu_beatmap.beatmapset_id}|#{osu_beatmap.id}|0|0|0|"
  end

  def search_set(conn, %{"s" => s}) do
    # TODO: Check authentication
    osu_beatmap = Repo.one! from ob in OsuBeatmap,
      join: obs in assoc(ob, :beatmapset),
      where: obs.id == ^s,
      preload: [beatmapset: obs]
    render conn, "response.raw", data: format_direct(osu_beatmap)
  end

  def search_set(conn, %{"b" => b}) do
    # TODO: Check authentication
    osu_beatmap = Repo.one! from ob in OsuBeatmap,
      join: obs in assoc(ob, :beatmapset),
      where: ob.id == ^b,
      preload: [beatmapset: obs]
    render conn, "response.raw", data: format_direct(osu_beatmap)
  end

  def bancho_connect(conn, _params) do
    render conn, "response.raw", data: "ca"
  end

  def osu_metrics(conn, _params) do
    render conn, "response.raw", data: <<>>
  end

  def check_updates(conn, _params) do
    data = """
    [{"file_version":"3","filename":"avcodec-51.dll","file_hash":"b22bf1e4ecd4be3d909dc68ccab74eec","filesize":"4409856","timestamp":"2014-08-18 16:16:59","patch_id":"1349","url_full":"http://m1.ppy.sh/r/avcodec-51.dll/f_b22bf1e4ecd4be3d909dc68ccab74eec","url_patch":"http://m1.ppy.sh/r/avcodec-51.dll/p_b22bf1e4ecd4be3d909dc68ccab74eec_734e450dd85c16d62c1844f10c6203c0"}]
    """
    render conn, "response.raw", data: data
  end

  def lastfm(conn, _params) do
    render conn, "response.raw", data: <<>>
  end

  ## Score helpers

  defp format_beatmap_header(ranked_status, osu_beatmap) do
    "#{ranked_status}|false|#{osu_beatmap.id}|#{osu_beatmap.beatmapset_id}|#{length osu_beatmap.scores}\n"
  end

  defp format_beatmap_song_info() do
    "[bold:0,size:20]|\n"
  end

  defp osu_date_to_unix_timestamp(date) do
    {:ok, datetime} = Timex.parse(date, "{YY}{M}{D}{h24}{m}{s}")
    Timex.to_unix(datetime)
  end

  defp format_score(score, place) do
    "#{score.id}|#{score.user.username}|#{score.score}|#{score.max_combo}"
    <> "|#{score.count_50}|#{score.count_100}|#{score.count_300}|#{score.miss_count}"
    <> "|#{score.katu_count}|#{score.geki_count}|#{score.full_combo}"
    <> "|#{score.mods}|#{score.user.id}|#{place}|#{osu_date_to_unix_timestamp(score.time)}"
    <> "|#{if score.has_replay do 1 else 0 end}"
    <> "\n"
  end

  defp format_personal_best(osu_beatmap, username, game_mode) do
    %OsuBeatmap{file_md5: file_md5} = osu_beatmap

    {game_mode, _} = Integer.parse(game_mode)

    query = from s in Score,
      join: s_ in fragment("
        SELECT row_number, id
        FROM
          (SELECT
             row_number()
             OVER (
               ORDER BY score DESC),
             id, username
           FROM
             (SELECT DISTINCT ON (sc.user_id) sc.id, score, username
              FROM scores sc
                JOIN users u ON u.id = sc.user_id
              WHERE
                u.banned = FALSE
                AND sc.file_md5 = (?)
                AND (completed = 2 OR completed = 3)
                AND sc.game_mode = (?)
              ORDER BY sc.user_id, sc.score DESC
             ) sc) sc
        WHERE username = (?)
      ", ^file_md5, ^game_mode, ^username),
        on: s.id == s_.id,
      join: u in assoc(s, :user),
      preload: [user: u],
      select: {s, s_.row_number}

    case Repo.one query do
      nil ->
        "\n"
      {score, place} ->
        format_score(score, place)
    end
  end

  def status(conn, _) do
    query = from s in Score,
      limit: 1
    Repo.one query

    json(conn, %{})
  end

  defp format_beatmap_top_scores(osu_beatmap) do
    {acc, _} = Enum.reduce osu_beatmap.scores, {"", 0}, fn score, {acc, index} ->
      acc = acc <> format_score(score, index + 1)

      {acc, index + 1}
    end

    acc
  end

  defp format_beatmap(ranked_status, osu_beatmap, username, game_mode) do
    # ranked_status:
    # 2: up to date
    # 1: update available
    # 0: latest pending
    # -1: not submitted
    # ranked_status = 1
    cond do
      ranked_status == 2 or (@everything_is_ranked and ranked_status == 0) ->
        format_beatmap_header(@ranked_status_up_to_date, osu_beatmap)
        <> "0\n" # nothing?
        <> format_beatmap_song_info
        <> "0\n" # beatmap appreciation
        <> format_personal_best(osu_beatmap, username, game_mode)
        <> format_beatmap_top_scores(osu_beatmap)
      true ->
        format_beatmap_header(ranked_status, osu_beatmap)
        <> "0\n" # nothing?
        <> format_beatmap_song_info
        <> "0\n" # beatmap appreciation
    end
  end

  defp stop(conn, status_code) do
    conn
    |> put_status(status_code)
    |> html("")
  end

  defp stop_plug(conn, status_code) do
    stop(conn, status_code)
    |> halt
  end
end
