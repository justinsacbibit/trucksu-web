defmodule Trucksu.ScoreController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    Performance,
    Session,

    Repo,
    Beatmap,
    OsuBeatmap,
    User,
    Score,
  }

  def create(conn, %{"osuver" => osuver} = params) do
    key = "osu!-scoreburgr---------#{osuver}"

    actually_create(conn, params, key)
  end

  def create(conn, params) do
    key = "h89f2-890h2h89b34g-h80g134n90133"

    actually_create(conn, params, key)
  end

  defp actually_create(conn, %{"score" => score, "iv" => iv, "pass" => pass, "score_file" => replay} = params, key) do

    url = Application.get_env(:trucksu, :decryption_url)
    score = if url do
      body = {:form, [{"c", score}, {"iv", iv}, {"k", key}]}
      %HTTPoison.Response{body: score} = HTTPoison.post!(url, body)
      score
    else
      {score, 0} = System.cmd("php", ["score.php", key, score, iv])
      score
    end
    score_data = String.split(score, ":")

    [
      beatmap_file_md5,
      username,
      _,
      count_300,
      count_100,
      count_50,
      count_geki,
      count_katu,
      count_miss,
      score,
      max_combo,
      full_combo,
      rank,
      mods,
      passed,
      game_mode,
      score_datetime
      | _osu_version
    ] = score_data

    username = String.rstrip(username)

    case Session.authenticate(username, pass, true) do
      {:error, _reason} ->
        # TODO: Return a 403 instead of 500
        raise "Invalid username or password"
      _ ->
        :ok
    end

    full_combo = case full_combo do
      "True" -> 1
      _ -> 0
    end

    #passed = case passed do
      #"True" -> 1
      #_ -> 0
    #end

    completed = case params["x"] do
      nil -> 2
      completed ->
        {int, _} = Integer.parse(completed)
        int
    end

    user = Repo.one! from u in User,
      join: s in assoc(u, :stats),
      where: s.game_mode == ^game_mode,
      where: u.username == ^username,
      preload: [stats: s]
    [stats] = user.stats

    {count_300, _} = Integer.parse(count_300)
    {count_100, _} = Integer.parse(count_100)
    {count_50, _} = Integer.parse(count_50)
    {count_miss, _} = Integer.parse(count_miss)

    cond do
      completed >= 2 ->
        top_score = Repo.one from s in Score,
          join: b in assoc(s, :beatmap),
          join: u in assoc(s, :user),
          where: b.file_md5 == ^beatmap_file_md5
            and u.username == ^username
            and s.game_mode == ^game_mode,
          order_by: [desc: s.score],
          limit: 1

        {score, _} = Integer.parse(score)

        score_difference = case top_score do
          nil ->
            score
          top_score ->
            cond do
              score > top_score ->
                score - top_score.score
              true ->
                0
            end
        end

        new_score = stats.ranked_score + score_difference

        total_points_of_hits = count_50 * 50 + count_100 * 100 + count_300 * 300
        total_number_of_hits = count_miss + count_50 + count_100 + count_300
        accuracy = total_points_of_hits / (total_number_of_hits * 300)

        {:ok, score} = Repo.transaction fn ->
          query = from b in Beatmap,
            where: b.file_md5 == ^beatmap_file_md5
          beatmap = case Repo.one query do
            nil ->
              # TODO: Now that we insert the beatmap as the result of a
              # changeAction packet, this should never happen.
              params = %{
                file_md5: beatmap_file_md5,
              }
              Repo.insert! Beatmap.changeset(%Beatmap{}, params)

            beatmap ->
              beatmap
          end

          score = Score.changeset(%Score{}, %{
            beatmap_id: beatmap.id,
            user_id: user.id,
            score: score,
            max_combo: max_combo,
            full_combo: full_combo,
            mods: mods,
            count_300: count_300,
            count_100: count_100,
            count_50: count_50,
            katu_count: count_katu,
            geki_count: count_geki,
            miss_count: count_miss,
            time: score_datetime,
            game_mode: game_mode,
            accuracy: accuracy,
            completed: completed,
            has_replay: true,
            rank: rank,
          })
          # IO.inspect score

          score = Repo.insert! score

          score = case Performance.calculate(score) do
            {:ok, pp} ->
              Logger.info "Calculated a pp of #{pp} for #{user.username} for score id #{score.id}"
              changeset = Ecto.Changeset.change(score, %{pp: pp})
              Repo.update! changeset
            {:error, error} ->
              Logger.error "Failed to calculate pp for score: #{inspect score}"
              Logger.error "Error: #{inspect error}"

              score
          end

          bucket = Application.get_env(:trucksu, :replay_file_bucket)
          replay_file_content = File.read!(replay.path)
          ExAws.S3.put_object!(bucket, "#{score.id}", replay_file_content)
          Logger.info "Uploaded replay for #{user.username}, score id #{score.id}, byte size: #{replay_file_content |> byte_size}"

          Logger.info "Inserting score: #{inspect score}"

          user_id = user.id

          [pp: new_pp, accuracy: new_accuracy] = Performance.calculate_stats_for_user(user_id, game_mode)

          Repo.update! Ecto.Changeset.change stats,
            ranked_score: new_score,
            total_score: new_score,
            playcount: stats.playcount + 1,
            total_hits: stats.total_hits + count_300 + count_100 + count_50,
            accuracy: new_accuracy,
            pp: new_pp

          score = Repo.preload score, :beatmap

          score
        end

        bancho_url = Application.get_env(:trucksu, :bancho_url)
        bot_url = Application.get_env(:trucksu, :bot_url)
        cookie = Application.get_env(:trucksu, :server_cookie)
        if score.pp do
          osu_beatmap = Repo.get_by OsuBeatmap, file_md5: score.beatmap.file_md5
          # TODO: Error logging
          data = %{
            "cookie" => cookie,
            "event_type" => "pp",
            "pp" => "#{round score.pp}",
            "username" => user.username,
            "beatmap_id" => "#{osu_beatmap.beatmap_id}",
            "version" => osu_beatmap.version,
            "artist" => osu_beatmap.artist,
            "title" => osu_beatmap.title,
            "creator" => osu_beatmap.creator,
          }
          json = Poison.encode! data
          response = HTTPoison.post bancho_url <> "/event", json, [{"Content-Type", "application/json"}], timeout: 20000, recv_timeout: 20000

          case response do
            {:ok, _response} ->
              :ok
              Logger.warn "Sent pp event to Bancho: #{inspect data}"
            {:error, response} ->
              Logger.error "Failed to send pp event to Bancho: #{inspect response}"
          end

          response = HTTPoison.post bot_url <> "/event", json, [{"Content-Type", "application/json"}], timeout: 20000, recv_timeout: 20000

          case response do
            {:ok, _response} ->
              :ok
              Logger.warn "Sent pp event to Bot: #{inspect data}"
            {:error, response} ->
              Logger.error "Failed to send pp event to Bot: #{inspect response}"
          end
        end

        render conn, "response.raw", data: build_response(score)
      true ->
        # User failed or retried

        user_stats = Ecto.Changeset.change stats,
          playcount: stats.playcount + 1,
          total_hits: stats.total_hits + count_300 + count_100 + count_50

        Repo.update! user_stats

        render conn, "response.raw", data: <<>>
    end
  end

  defp build_response(score) do
    "beatmapId:#{1}"
    <> "|beatmapSetId:#{2}"
    <> "|beatmapPlaycount:#{5}"
    <> "|beatmapPasscount:#{4}"
    <> "|approvedDate:#{"2014-05-05 20:02:30"}\n"
    <> "chartId:#{"overall"}"
    <> "|chartName:#{"Overall Ranking"}"
    <> "|chartEndDate:#{""}"
    <> "|beatmapRankingBefore:#{1}"
    <> "|beatmapRankingAfter:#{1}"
    <> "|rankedScoreBefore:#{1}"
    <> "|rankedScoreAfter:#{1}"
    <> "|totalScoreBefore:#{1}"
    <> "|totalScoreAfter:#{1}"
    <> "|playCountBefore:#{1}"
    <> "|accuracyBefore:#{1}"
    <> "|accuracyAfter:#{1}"
    <> "|rankBefore:#{1}"
    <> "|rankAfter:#{1}"
    <> "|toNextRank:#{1}"
    <> "|toNextRankUser:#{"MEME"}"
    <> "|achievements:#{""}"
    <> "|achievements-new:#{""}"
    <> "|onlineScoreId:#{score.id}\n"
  end
end

