defmodule Trucksu.Performance do
  require Logger
  import Ecto.Query, only: [from: 2]
  alias Trucksu.{
    Accuracy,
    OsuBeatmapFileFetcher,

    Repo,
    Score,
    UserStats,
  }

  @doc """
  Calculates the total pp and accuracy for a user, for a certain game mode.

  Only takes into account scores which have pp already calculated.

  The update_missing/0 function can calculate and update scores which are
  missing pp values.
  """
  def calculate_stats_for_user(user_id, game_mode) do
    scores = Repo.all from s in Score,
      where: s.user_id == ^user_id
        and s.game_mode == ^game_mode
        and (s.completed == 2 or s.completed == 3)
        and not is_nil(s.pp),
      distinct: s.beatmap_id

    # TODO: Sort in SQL using a subquery
    scores = Enum.sort(scores, &(&1.pp > &2.pp))
    calculate_stats_for_scores(scores)
  end

  defp calculate_stats_for_scores(scores) do
    accuracy = Accuracy.from_accuracies(Enum.map scores, fn %Score{accuracy: accuracy} -> accuracy end)
    pp = from_pps(Enum.map scores, fn %Score{pp: pp} -> pp end)

    [pp: pp, accuracy: accuracy]
  end

  defp from_pps(pps) do
    {pp, _} = Enum.reduce pps, {0, 0}, fn pp, {total_pp, index} ->
      factor = :math.pow(0.95, index)

      {total_pp + pp * factor, index + 1}
    end

    pp
  end

  @doc """
  Updates each user's pp and accuracy according to the current state of their scores.
  """
  def update_total_for_all_users(dry_run \\ false) do
    user_stats = Repo.all from us in UserStats,
      join: u in assoc(us, :user),
      join: s in assoc(u, :scores),
      where: us.game_mode == s.game_mode
        and (s.completed == 2 or s.completed == 3)
        and not is_nil(s.pp),
      order_by: [desc: s.pp],
      distinct: [u.id, s.beatmap_id, s.game_mode],
      preload: [scores: s, user: u]

    Enum.each user_stats, fn user_stats ->
      # TODO: Sort in SQL using a subquery
      scores = Enum.sort(user_stats.scores, &(&1.pp > &2.pp))
      calculated = calculate_stats_for_scores(scores)
      [pp: pp, accuracy: accuracy] = calculated

      changeset = Ecto.Changeset.change(user_stats, %{
        pp: pp,
        accuracy: accuracy,
      })

      if not dry_run do
        Logger.warn "Updating #{user_stats.user.username} stats: pp=#{pp} accuracy=#{accuracy}"
        case Repo.insert changeset do
          {:ok, _} ->
            :ok
          {:error, changeset} ->
            Logger.error "Failed to insert updated user_stats for #{user_stats.user.username}"
            Logger.error inspect changeset
        end
      else
        Logger.warn "Would update #{user_stats.user.username} stats: pp=#{pp} accuracy=#{accuracy}"
      end
    end
  end

  @doc """
  Calculates the missing pp values in the database. Useful for when the
  performance server was unreachable during score submission.

  TODO: Make sure that this doesn't attempt to calculate pp for maps that don't
  exist in the osu! API.
  """
  def update_missing() do
    # TODO
  end

  def calculate(score) do
    score = Repo.preload score, :beatmap
    with {:ok, osu_file_content} <- OsuBeatmapFileFetcher.fetch(score.beatmap.file_md5),
         do: calculate_with_osu_file_content(score, osu_file_content)
  end

  defp calculate_with_osu_file_content(score, osu_file_content) do
    form_data = [
      {"b", osu_file_content},
      {"Count300", score.count_300},
      {"Count100", score.count_100},
      {"Count50", score.count_50},
      {"CountMiss", score.miss_count},
      {"MaxCombo", score.max_combo},
      {"EnabledMods", score.mods},
      {"GameMode", score.game_mode},
    ]

    performance_url = Application.get_env(:trucksu, :performance_url)
    case HTTPoison.post performance_url, {:form, form_data} do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Poison.decode(body) do
          {:ok, %{"pp" => pp}} ->
            {:ok, pp}
          _ ->
            {:error, :json_error}
        end
      {:error, response} ->
        Logger.error "Failed to calculate pp for score: #{inspect score}"
        Logger.error "Response: #{inspect response}"
        {:error, :performance_error}
    end
  end
end

