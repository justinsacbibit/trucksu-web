defmodule Trucksu.OsuWebController do
  use Trucksu.Web, :controller
  use Timex
  require Logger
  alias Trucksu.{
    OsuBeatmapFetcher,
    OsuBeatmapFileFetcher,
    OsuBeatmapsetFetcher,
    Session,

    Friendship,
    OsuBeatmap,
    OsuBeatmapset,
    Score,
  }

  @ranking_type_global_selected_mods 2
  @ranking_type_global 1
  @ranking_type_country 4
  @ranking_type_friend 3

  @ranked_status_not_submitted -1
  @ranked_status_up_to_date 2
  @ranked_status_update_available 1

  @everything_is_ranked true

  plug :authenticate when action in [:get_scores, :search_set] # TODO: add :show_map?
  # TODO: Implement rate limiting
  plug :fetch_osu_beatmap when action == :get_scores

  def show_map(conn, %{"filename" => filename}) do
    # TODO: Should this use OsuBeatmapFetcher first?
    osu_beatmap = Repo.get_by! OsuBeatmap, filename: filename
    {:ok, osu_file_content} = OsuBeatmapFileFetcher.fetch(osu_beatmap.id)
    # TODO: Content-Type header?
    conn
    |> send_resp(200, osu_file_content)
  end

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
      osu_beatmap.filename == filename
    end)
  end

  defp fetch_osu_beatmap(%Plug.Conn{params: %{"f" => filename, "c" => file_md5, "i" => beatmapset_id}} = conn, _opts) do
    {beatmapset_id, _} = Integer.parse(beatmapset_id)
    OsuBeatmapsetFetcher.fetch(beatmapset_id)

    osu_beatmap = Repo.one from ob in OsuBeatmap,
      join: obs in assoc(ob, :beatmapset),
      where: ob.file_md5 == ^file_md5 and obs.id == ^beatmapset_id,
      preload: [beatmapset: obs]

    {status, osu_beatmap} = case osu_beatmap do
      nil ->

        query = from obs in OsuBeatmapset,
          join: ob in assoc(obs, :beatmaps),
          where: obs.id == ^beatmapset_id,
          preload: [beatmaps: ob]
        case Repo.one query do
          nil ->
            # We don't have the beatmapset
            {:not_submitted, nil}

          osu_beatmapset ->
            Logger.debug "We have some version of the beatmapset"

            osu_beatmap = find_beatmap_with_filename_in_set(osu_beatmapset, filename)

            status = case osu_beatmap do
              nil -> :not_submitted
              _ -> :update_available
            end

            {status, osu_beatmap}
        end

      _ ->
        {:up_to_date, osu_beatmap}
    end

    conn
    |> assign(:beatmap_status, status)
    |> assign(:osu_beatmap, osu_beatmap)
  end

  def get_scores(conn, %{"c" => _file_md5, "i" => _beatmapset_id, "f" => _filename, "m" => game_mode, "v" => type, "mods" => mods}) do
    {type, _} = Integer.parse(type)

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
      @ranking_type_global_selected_mods ->

        {mods, _} = Integer.parse(mods)

        from s in Score,
          join: u in assoc(s, :user),
          where: u.banned == false
            and s.file_md5 == ^file_md5
            and s.game_mode == ^game_mode
            and s.mods == ^mods
            and s.pass,
          order_by: [desc: s.score],
          preload: [user: u]

      @ranking_type_friend ->

        user_id = user.id
        from s in Score,
          join: f in Friendship,
          on: (f.requester_id == ^user_id
            and s.user_id == f.receiver_id)
            or s.user_id == ^user_id,
          join: u in assoc(s, :user),
          where: u.banned == false
            and s.file_md5 == ^file_md5
            and s.game_mode == ^game_mode
            and s.pass,
          order_by: [desc: s.score],
          preload: [user: u]

      @ranking_type_country ->
        # country ranking

        country = user.country
        from s in Score,
          join: u in assoc(s, :user),
          where: u.banned == false
            and s.file_md5 == ^file_md5
            and s.game_mode == ^game_mode
            and u.country == ^country
            and s.pass,
          order_by: [desc: s.score],
          preload: [user: u]

      _ ->
        from s in Score,
          join: u in assoc(s, :user),
          where: u.banned == false
            and s.file_md5 == ^file_md5
            and s.game_mode == ^game_mode
            and s.pass,
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
    has_video = 0 # 0 = no video, 1 = has video
    "#{osu_beatmap.beatmapset_id}.osz|#{osu_beatmap.beatmapset.artist}|#{osu_beatmap.beatmapset.title}|#{osu_beatmap.beatmapset.creator}|#{osu_beatmap.beatmapset.approved}|10.00000|1|#{osu_beatmap.beatmapset_id}|#{osu_beatmap.id}|#{has_video}|0|0|"
  end

  def search_set(conn, %{"s" => s}) do
    # TODO: Check authentication
    {s, _} = Integer.parse(s)
    OsuBeatmapsetFetcher.fetch(s)
    osu_beatmap = Repo.one! from ob in OsuBeatmap,
      join: obs in assoc(ob, :beatmapset),
      where: obs.id == ^s,
      preload: [beatmapset: obs],
      limit: 1
    render conn, "response.raw", data: format_direct(osu_beatmap)
  end

  def search_set(conn, %{"b" => b}) do
    # TODO: Check authentication
    {b, _} = Integer.parse(b)
    OsuBeatmapFetcher.fetch(b)
    osu_beatmap = Repo.one! from ob in OsuBeatmap,
      join: obs in assoc(ob, :beatmapset),
      where: ob.id == ^b,
      preload: [beatmapset: obs],
      limit: 1
    render conn, "response.raw", data: format_direct(osu_beatmap)
  end

  def bancho_connect(conn, _params) do
    render conn, "response.raw", data: "ca"
  end

  def osu_metrics(conn, _params) do
    render conn, "response.raw", data: <<>>
  end

  def check_updates(conn, params) do
    data = if Mix.env == :dev do
      "[]"
    else
      case HTTPoison.get("https://osu.ppy.sh/web/check-updates.php", [], params: Enum.to_list(params)) do
        {:ok, %HTTPoison.Response{body: body}} when byte_size(body) > 0 ->
          body
        _ ->
          "[]"
      end
    end
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
                AND sc.pass
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

  # def screenshot(conn, %{"ss_file" => ss_file, "i" => user_id} = params) do
  #   IO.inspect params, [limit: :infinity]
  #   # TODO: Process list
  #   ss_file_content = File.read!(ss_file.path)
  #   if byte_size(ss_file_content) > 0 do
  #     bucket = Application.get_env(:trucksu, :desktop_screenshot_file_bucket)
  #     ExAws.S3.put_object!(bucket, "#{user_id}-#{Time.now |> Time.to_milliseconds}.jpg", ss_file_content)
  #   else
  #     Logger.info "No screenshot file content for #{user_id}"
  #   end
  #   conn |> html("")
  # end
  def screenshot(conn, params) do
    IO.inspect params, [limit: :infinity]
    conn |> html("")
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
