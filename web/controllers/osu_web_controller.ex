defmodule Trucksu.OsuWebController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    Session,

    Beatmap,
    Friendship,
    Score,
    User,
  }

  plug :authenticate

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

  def get_scores(conn, %{"c" => file_md5, "i" => beatmapset_id, "f" => filename, "m" => mode, "v" => type, "mods" => mods} = params) do

    user = conn.assigns[:user]

    query = from b in Beatmap,
      where: b.file_md5 == ^file_md5

    beatmap = case Repo.one query do
      nil ->
        params = %{
          filename: filename,
          beatmapset_id: beatmapset_id,
          file_md5: file_md5,
        }
        beatmap = Repo.insert! Beatmap.changeset(%Beatmap{}, params)
        Repo.preload beatmap, :scores

      beatmap ->

        if is_nil(beatmap.filename) do
          # This beatmap was inserted as the result of a changeAction packet or
          # a score submission. The beatmap is missing a filename and
          # beatmapset_id, so let's fill that in now.
          params = %{
            filename: filename,
            beatmapset_id: beatmapset_id,
            file_md5: file_md5,
          }
          Repo.update! Beatmap.changeset(beatmap, params)
        end

        # type
        # 4 - country ranking
        # 1 - global ranking
        # 2 - global ranking (selected mods)
        # 3 - friend ranking

        beatmap_id = beatmap.id
        preload_query = case type do
          "2" ->
            # global ranking (selected mods)

            {mods, _} = Integer.parse(mods)

            from s in Score.completed,
              join: u in assoc(s, :user),
              where: s.beatmap_id == ^beatmap_id
                and s.game_mode == ^mode
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
              where: s.beatmap_id == ^beatmap_id
                and s.game_mode == ^mode,
              order_by: [desc: s.score],
              preload: [user: u]

          "4" ->
            # country ranking

            country = user.country
            from s in Score.completed,
              join: u in assoc(s, :user),
              where: s.beatmap_id == ^beatmap_id
                and s.game_mode == ^mode
                and u.country == ^country,
              order_by: [desc: s.score],
              preload: [user: u]

          _ ->
            from s in Score.completed,
              join: u in assoc(s, :user),
              where: s.beatmap_id == ^beatmap_id and s.game_mode == ^mode,
              order_by: [desc: s.score],
              preload: [user: u]
        end

        beatmap = Repo.preload beatmap, scores: preload_query

        # TODO: Filter in SQL with subquery
        scores = Enum.uniq_by(beatmap.scores, &(&1.user_id))

        %{beatmap | scores: scores}
    end

    data = format_beatmap(2, beatmapset_id, beatmap, user.username, mode)
    render conn, "response.raw", data: data
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

  defp format_beatmap_header(ranked_status, beatmapset_id, beatmap) do
    "#{ranked_status}|false|#{beatmapset_id}|#{beatmapset_id}|#{length beatmap.scores}\n"
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

  defp format_personal_best(beatmap, username, game_mode) do
    beatmap_id = beatmap.id

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
              WHERE sc.beatmap_id = (?) AND (completed = 2 OR completed = 3) AND sc.game_mode = (?)
              ORDER BY sc.user_id, sc.score DESC
             ) sc) sc
        WHERE username = (?)
      ", ^beatmap_id, ^game_mode, ^username),
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

  defp format_beatmap_top_scores(beatmap) do
    {acc, _} = Enum.reduce beatmap.scores, {"", 0}, fn score, {acc, index} ->
      acc = acc <> format_score(score, index + 1)

      {acc, index + 1}
    end

    acc
  end

  defp format_beatmap(ranked_status, beatmapset_id, beatmap, username, game_mode) do
    format_beatmap_header(ranked_status, beatmapset_id, beatmap)
    <> "0\n" # nothing?
    <> format_beatmap_song_info
    <> "0\n" # beatmap appreciation
    <> format_personal_best(beatmap, username, game_mode)
    <> format_beatmap_top_scores(beatmap)
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

