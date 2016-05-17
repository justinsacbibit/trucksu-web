defmodule Trucksu.OsuWebController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    Osu,
    Session,

    Friendship,
    OsuBeatmap,
    OsuBeatmapset,
    Score,
    User,
  }

  @ranked_status_not_submitted -1
  @ranked_status_up_to_date 2
  @ranked_status_update_available 1

  plug :authenticate when not action in [:status]
  # TODO: Uncomment when rate limiting is implemented
  plug :fetch_osu_beatmap when action == :get_scores

  defp authenticate(conn, _) do
    case conn.request_path do
      "/osu/web/osu-osz2-getscores.php" ->
        username = conn.params["us"]
        password_md5 = conn.params["ha"]
        case Session.authenticate(username, password_md5, true) do
          {:error, reason} ->
            Logger.warn "#{username} attempted to get scores, but was unable to authenticate: #{reason}"
            stop_plug(conn, 403)
          {:ok, user} ->
            assign(conn, :user, user)
        end
      _ ->
        conn
    end
  end

  defp fetch_osu_beatmap(%Plug.Conn{params: %{"f" => filename, "c" => file_md5, "i" => beatmapset_id}} = conn, opts) do
    osu_beatmap = Repo.one from ob in OsuBeatmap,
      where: ob.file_md5 == ^file_md5
    case osu_beatmap do
      nil ->
        # Check the database then the API if necessary

        osu_beatmaps = Repo.all from ob in OsuBeatmap,
          where: ob.beatmapset_id == ^beatmapset_id

        case osu_beatmaps do
          [first_map | _] ->
            # We have some version of the beatmapset
            Logger.error "We have some version of the beatmapset"

            first_map = Enum.at(osu_beatmaps, 0)
            cond do
              # 3 = qualified, 2 = approved, 1 = ranked, 0 = pending, -1 = WIP, -2 = graveyard
              first_map.approved == 2 or first_map.approved == 1 ->
                # approved or ranked, client version either needs to be updated or is not submitted
                osu_beatmap = Enum.find(osu_beatmaps, fn(osu_beatmap) ->
                  version = osu_beatmap.version
                  case Regex.named_captures(~r/\[(?<version>)\]\.osu$/, filename) do
                    %{"version" => ^version} ->
                      true

                    _ ->
                      false
                  end
                end)
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
                  osu_beatmap = Enum.find(osu_beatmaps, fn(osu_beatmap) ->
                    version = osu_beatmap.version
                    # osu doesn't include colons in filename difficulty
                    version = String.replace(version, ":", "")
                    case Regex.named_captures(~r/ \[(?<version>)\]\.osu$/, filename) do
                      %{"version" => ^version} ->
                        true

                      _ ->
                        false
                    end
                  end)
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
                  if fetch_set_from_osu_api(beatmapset_id) do
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

          _ ->
            # We don't have the beatmapset
            # Call osu! API
            if conn.assigns[:fetched_set] do
              conn
              |> assign(:beatmap_status, :not_submitted)
              |> assign(:osu_beatmap, nil)
            else
              if fetch_set_from_osu_api(beatmapset_id) do
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


      _ ->
        # TODO: handle osu_beatmap.beatmapset_id != beatmapset_id

        # Check the database then the API if not ranked
        cond do
          # 3 = qualified, 2 = approved, 1 = ranked, 0 = pending, -1 = WIP, -2 = graveyard
          osu_beatmap.approved == 2 or osu_beatmap.approved == 1 ->
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
              if fetch_set_from_osu_api(beatmapset_id) do
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

  defp fetch_set_from_osu_api(beatmapset_id) do
    # TODO: Rate limit
    Logger.error "Fetch beatmapset #{beatmapset_id}"

    case Osu.get_beatmaps(s: beatmapset_id) do
      {:ok, %HTTPoison.Response{body: [first_beatmap] = beatmap_maps}} ->
        Repo.transaction(fn ->

          changeset = OsuBeatmapset.changeset_from_api(%OsuBeatmapset{}, first_beatmap)
          case Repo.insert changeset do
            {:ok, _osu_beatmapset} ->
              for beatmap_map <- beatmap_maps do
                case Repo.get_by OsuBeatmap, file_md5: beatmap_map["file_md5"] do
                  nil ->
                    changeset = OsuBeatmap.changeset_from_api(%OsuBeatmap{}, beatmap_map)
                    case Repo.insert changeset do
                      {:ok, osu_beatmap} ->
                        :ok
                      {:error, error} ->
                        Logger.error "Error occurred when trying to insert a beatmap from osu! API"
                        Logger.error inspect error
                        :ok
                    end
                  osu_beatmap ->
                    # This beatmap is already in the db
                    :ok
                end
              end
            {:error, error} ->
              Logger.error "Error occurred when trying to insert a beatmapset from osu! API"
              Logger.error inspect error
          end
        end)

        # succeeded
        true

      {:ok, _} ->
        # beatmap doesn't exist
        true

      {:error, error} ->
        Logger.error "Failed to get beatmapset #{beatmapset_id} from the osu! API"
        Logger.error inspect error

        # failed
        false

    end
  end

  def get_scores(conn, %{"c" => _file_md5, "i" => _beatmapset_id, "f" => _filename, "m" => game_mode, "v" => type, "mods" => mods} = params) do

    %{
      user: user,
      beatmap_status: beatmap_status,
      osu_beatmap: osu_beatmap,
    } = conn.assigns

    data = case beatmap_status do
      :not_submitted ->
        "-1"

      _ ->
        build_and_format_scores(user, osu_beatmap, beatmap_status, type, mods, game_mode)
    end

    conn |> html(data)
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
    "#{ranked_status}|false|#{123}|#{osu_beatmap.beatmapset_id}|#{length osu_beatmap.scores}\n"
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
    format_beatmap_header(ranked_status, osu_beatmap)
    <> "0\n" # nothing?
    <> format_beatmap_song_info
    <> "0\n" # beatmap appreciation
    <> format_personal_best(osu_beatmap, username, game_mode)
    <> format_beatmap_top_scores(osu_beatmap)
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

