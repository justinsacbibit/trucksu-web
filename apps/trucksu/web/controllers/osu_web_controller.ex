defmodule Trucksu.OsuWebController do
  use Trucksu.Web, :controller
  alias Trucksu.{Repo, Beatmap, Score}

  def bancho_connect(conn, _params) do
    render conn, "response.raw", data: "ca"
  end

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

  defp format_beatmap_top_scores(beatmap) do
    {acc, _} = Enum.reduce beatmap.scores, {"", 0}, fn score, {acc, index} ->
      acc = acc
      <> "#{score.id}|#{score.user.username}|#{score.score}|#{score.max_combo}"
      <> "|#{score.count_50}|#{score.count_100}|#{score.count_300}|#{score.miss_count}"
      <> "|#{score.katu_count}|#{score.geki_count}|#{score.full_combo}"
      <> "|#{score.mods}|#{score.user.id}|#{index + 1}|#{osu_date_to_unix_timestamp(score.time)}|0\n" # the 0 is has_replay

      {acc, index + 1}
    end

    acc
  end

  defp format_beatmap(ranked_status, beatmapset_id, beatmap) do
    format_beatmap_header(ranked_status, beatmapset_id, beatmap)
    <> "0\n" # nothing?
    <> format_beatmap_song_info
    <> "0\n\n" # beatmap appreciation
    <> format_beatmap_top_scores(beatmap)
  end

  def get_scores(conn, %{"c" => file_md5, "i" => beatmapset_id, "f" => filename, "us" => username, "m" => mode, "v" => type} = params) do

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
        beatmap_id = beatmap.id
        preload_query = from s in Score,
          join: u in assoc(s, :user),
          where: s.completed == 2 or s.completed == 3,
          where: s.beatmap_id == ^beatmap_id,
          order_by: [desc: s.score],
          distinct: s.user_id,
          preload: [user: u]

        Repo.preload beatmap, scores: preload_query
    end

    data = format_beatmap(2, beatmapset_id, beatmap)
    render conn, "response.raw", data: data
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
end

