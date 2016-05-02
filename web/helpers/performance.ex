defmodule Trucksu.Performance do
  require Logger
  import Ecto.Query, only: [from: 2]
  alias Trucksu.{
    Accuracy,
    OsuBeatmapFileFetcher,

    Repo,
    Beatmap,
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
      join: b in assoc(s, :beatmap),
      where: s.user_id == ^user_id
        and s.game_mode == ^game_mode
        and (s.completed == 2 or s.completed == 3)
        and not is_nil(s.pp),
      order_by: [desc: s.pp],
      preload: [beatmap: b]

    # TODO: Filter in SQL using a subquery
    unique_by_md5 = fn %Score{beatmap: %Beatmap{file_md5: file_md5}} ->
      file_md5
    end
    scores = Enum.uniq_by(scores, &(unique_by_md5.(&1)))
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
  def update_total_for_all_users(game_mode \\ 0, dry_run \\ false) do
    user_stats = Repo.all from us in UserStats,
      join: u in assoc(us, :user),
      where: us.game_mode == ^game_mode,
      preload: [user: u]

    Enum.each user_stats, fn user_stats ->
      # TODO: Sort in SQL using a subquery
      calculated = calculate_stats_for_user(user_stats.user_id, user_stats.game_mode)
      [pp: pp, accuracy: accuracy] = calculated

      changeset = Ecto.Changeset.change(user_stats, %{
        pp: pp / 1,
        accuracy: accuracy / 1,
      })

      if not dry_run do
        Logger.warn "Updating #{user_stats.user.username}:#{user_stats.game_mode} pp:old=#{user_stats.pp} accuracy:old=#{user_stats.accuracy} pp=#{pp} accuracy=#{accuracy}"
        case Repo.update changeset do
          {:ok, _} ->
            :ok
          {:error, changeset} ->
            Logger.error "Failed to insert updated user_stats for #{user_stats.user.username}:#{user_stats.game_mode}"
            Logger.error inspect changeset
        end
      else
        Logger.warn "Would update #{user_stats.user.username}:#{user_stats.game_mode} pp:old=#{user_stats.pp} accuracy:old=#{user_stats.accuracy} pp=#{pp} accuracy=#{accuracy}"
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

  @doc """
  Recalculate scores which already have a pp calculated.

  update_total_for_all_users/1 should be called after, to update each user's
  user_stats.
  """
  def recalculate_all(dry_run \\ false) do
    if dry_run do
      Logger.warn "recalculate_all/1 dry-run"
    else
      Logger.warn "recalculate_all/1 non-dry-run"
    end

    scores = Repo.all from s in Score,
      join: u in assoc(s, :user),
      where: not is_nil(s.pp),
      preload: [user: u]

    for score <- scores do
      case calculate(score) do
        {:ok, pp} ->
          changeset = Ecto.Changeset.change(score, %{pp: pp})
          if not dry_run do
            Logger.info "Updating pp from #{score.pp} to #{pp} for #{score.user.username} for score id #{score.id}"
            Repo.update! changeset
          else
            Logger.info "Would update pp from #{score.pp} to #{pp} for #{score.user.username} for score id #{score.id}"
          end
        {:error, error} ->
          Logger.error "Failed to calculate pp for score: #{inspect score}"
          Logger.error "Error: #{inspect error}"
      end
    end
  end

  def calculate(score) do
    score = Repo.preload score, :beatmap
    with {:ok, osu_file_content} <- OsuBeatmapFileFetcher.fetch(score.beatmap.file_md5),
         do: calculate_with_osu_file_content(score, osu_file_content)
  end

  def calculate(beatmap_id, mods, game_mode) when is_integer(beatmap_id) do
    with {:ok, osu_file_content} <- OsuBeatmapFileFetcher.fetch(beatmap_id),
         do: calculate_max_with_osu_file_content(mods, game_mode, osu_file_content)
  end

  defp calculate_with_osu_file_content(score, osu_file_content) do
    beatmap = Repo.preload score.beatmap, :osu_beatmap

    form_data = [
      {"b", osu_file_content},
      {"Count300", score.count_300},
      {"Count100", score.count_100},
      {"Count50", score.count_50},
      {"CountMiss", score.miss_count},
      {"MaxCombo", score.max_combo},
      {"EnabledMods", score.mods},
      {"GameMode", score.game_mode},
      {"MapMaxCombo", beatmap.osu_beatmap.max_combo},
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

  defp calculate_max_with_osu_file_content(mods, game_mode, osu_file_content) do

    form_data = [
      {"b", osu_file_content},
      {"EnabledMods", mods},
      {"GameMode", game_mode},
    ]

    performance_url = Application.get_env(:trucksu, :performance_url)
    case HTTPoison.post performance_url <> "/max", {:form, form_data} do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Poison.decode(body) do
          {:ok, %{"pp" => pp}} ->
            {:ok, pp}
          _ ->
            {:error, :json_error}
        end
      {:error, response} ->
        Logger.error "Failed to calculate max pp"
        Logger.error "Response: #{inspect response}"
        {:error, :performance_error}
    end
  end
end

