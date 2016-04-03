defmodule Trucksu.ScoreController do
  use Trucksu.Web, :controller
  alias Trucksu.Session
  alias Trucksu.{Repo, Beatmap, User, Score}

  def create(conn, %{"score" => score, "iv" => iv, "pass" => pass, "osuver" => osuver} = params) do
    key = "osu!-scoreburgr---------#{osuver}"
    {:ok, score} = File.read(score.path)
    IO.inspect score

    raise "no"
  end

  @key "h89f2-890h2h89b34g-h80g134n90133"

  def create(conn, %{"score" => score, "iv" => iv, "pass" => pass, "score_file" => score_file} = params) do
    {score, 0} = System.cmd("php", ["apps/trucksu/score.php", @key, score, iv])
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

    case Session.authenticate(username, pass, true) do
      :error ->
        raise "no"
      _ ->
        :ok
    end

    full_combo = case full_combo do
      "True" -> 1
      _ -> 0
    end

    passed = case passed do
      "True" -> 1
      _ -> 0
    end

    completed = case params["x"] do
      nil -> 2
      completed -> completed
    end

    cond do
      completed >= 2 ->
        top_score = Repo.one from s in Score,
          join: b in assoc(s, :beatmap),
          join: u in assoc(s, :user),
          where: b.file_md5 == ^beatmap_file_md5
            and u.username == ^username
            and s.game_mode == ^game_mode,
          order_by: [desc: s.score]

        user = Repo.one! from u in User,
          join: s in assoc(u, :stats),
          where: s.game_mode == ^game_mode,
          preload: [stats: s]

        {score, _} = Integer.parse(score)

        score_difference = case top_score do
          nil ->
            score
          top_score ->
            score - top_score.score
        end

        [stats] = user.stats
        new_score = stats.ranked_score + score_difference

        {count_300, _} = Integer.parse(count_300)
        {count_100, _} = Integer.parse(count_100)
        {count_50, _} = Integer.parse(count_50)
        {count_miss, _} = Integer.parse(count_miss)

        total_points_of_hits = count_50 * 50 + count_100 * 100 + count_300 * 300
        total_number_of_hits = count_miss + count_50 + count_100 + count_300
        accuracy = total_points_of_hits / (total_number_of_hits * 300)

        Repo.transaction fn ->
          # TODO: Update accuracy
          user_stats = Ecto.Changeset.change stats,
            ranked_score: new_score,
            total_score: new_score,
            playcount: stats.playcount + 1,
            total_hits: count_300 + count_100 + count_50,
            accuracy: accuracy

          {:ok, _} = Repo.update user_stats

          query = from b in Beatmap,
            where: b.file_md5 == ^beatmap_file_md5
          beatmap = case Repo.one query do
            nil ->
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
          })
          IO.inspect score

          Repo.insert! score
        end
      true ->
        # TODO: Handle when a user failed/retried
        :ok
    end

    render conn, "response.raw", data: <<>>
  end
end

