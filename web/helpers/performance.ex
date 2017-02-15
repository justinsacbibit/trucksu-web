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

  The calculate_missing/0 function can calculate and update scores which are
  missing pp values.
  """
  def calculate_stats_for_user(user_id, game_mode) do
    scores = Repo.all from s in Score,
      join: ob in assoc(s, :osu_beatmap),
      where: s.user_id == ^user_id
        and s.game_mode == ^game_mode
        and s.pass
        and not is_nil(s.pp),
      order_by: [desc: s.pp],
      preload: [osu_beatmap: ob]

    calculate_stats_for_scores(scores)
  end

  def calculate_stats_for_scores(scores) do
    unique_by_md5 = fn %Score{file_md5: file_md5} ->
      file_md5
    end
    scores = Enum.uniq_by(scores, &(unique_by_md5.(&1)))

    # if the score's pp is above 600, turn it into a negative
    scores = for score <- scores, do: %{score | pp: (if score.pp > 600.0 do -score.pp else score.pp end)}
    # re-sort in descending order by pp
    scores = Enum.sort_by(scores, fn(score) -> score.pp end, &>=/2)

    accuracy = Accuracy.from_accuracies(Enum.map scores, fn %Score{accuracy: accuracy} -> accuracy end)
    pp = from_pps(Enum.map scores, fn %Score{pp: pp} -> pp end)

    pp = max(pp, 0.0)

    pp = pp + calculate_bonus_pp(length(scores))

    [pp: pp, accuracy: accuracy]
  end

  defp calculate_bonus_pp(score_count) do
    416.6667 * (1 - :math.pow(0.9994, score_count))
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

    results = Enum.map user_stats, fn user_stats ->
      calculated = calculate_stats_for_user(user_stats.user_id, user_stats.game_mode)
      [pp: pp, accuracy: accuracy] = calculated

      changeset = Ecto.Changeset.change(user_stats, %{
        pp: pp / 1,
        accuracy: accuracy / 1,
      })

      if not dry_run do
        case Repo.update changeset do
          {:ok, _} ->
            {:ok, user_stats.user, user_stats.pp, pp}
          {:error, changeset} ->
            Logger.error "Failed to update user_stats for #{user_stats.user.username}:#{user_stats.game_mode}: #{inspect changeset}"
            {:error, changeset}
        end
      else
        {:ok, user_stats.user, user_stats.pp, pp}
      end
    end

    for {:ok, user, old_pp, new_pp} <- results, old_pp != new_pp do
      if not dry_run do
        Logger.warn "Updated #{user.username}:#{game_mode} diff=#{round(new_pp - old_pp)} pp:old=#{round(old_pp)} pp=#{round(new_pp)}"
      else
        Logger.warn "Would update #{user.username}:#{game_mode} diff=#{round(new_pp - old_pp)} pp:old=#{round(old_pp)} pp=#{round(new_pp)}"
      end
    end
  end

  @doc """
  Calculates the missing pp values in the database. Useful for when the
  performance server was unreachable during score submission.
  """
  def calculate_missing() do
    scores = Repo.all from sc in Score,
      where: is_nil(sc.pp) or sc.pp == 0.00

    for score <- scores do
      case calculate(score) do
        {:ok, pp} ->
          changeset = Ecto.Changeset.change(score, pp: pp)
          Logger.warn "Updating score with pp=#{pp}: #{inspect score}"
          Repo.update! changeset
        {:error, _} ->
          :ok
      end
    end
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

  def calculate(%Score{game_mode: game_mode}) when game_mode != 0 do
    {:ok, nil}
  end
  def calculate(score) do
    with {:ok, osu_file_content} <- OsuBeatmapFileFetcher.fetch(score.file_md5),
         do: calculate_with_osu_file_content(score, osu_file_content)
  end

  def calculate(_identifier, _mods, game_mode, _acc) when game_mode != 0 do
    {:ok, nil}
  end
  def calculate(identifier, mods, game_mode, acc) do
    with {:ok, osu_file_content} <- OsuBeatmapFileFetcher.fetch(identifier),
         do: calculate_max_with_osu_file_content(mods, game_mode, osu_file_content, acc)
  end

  defp calculate_with_osu_file_content(score, osu_file_content) do
    score = Repo.preload score, :osu_beatmap

    cookie = Application.get_env(:trucksu, :performance_cookie)
    form_data = [
      {"b", osu_file_content},
      {"Count300", score.count_300},
      {"Count100", score.count_100},
      {"Count50", score.count_50},
      {"CountMiss", score.miss_count},
      {"MaxCombo", score.max_combo},
      {"EnabledMods", score.mods},
      {"GameMode", score.game_mode},
      {"MapMaxCombo", score.osu_beatmap.max_combo},
      {"Cookie", cookie},
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

  defp calculate_max_with_osu_file_content(mods, game_mode, osu_file_content, acc) do

    cookie = Application.get_env(:trucksu, :performance_cookie)
    form_data = [
      {"b", osu_file_content},
      {"EnabledMods", mods},
      {"GameMode", game_mode},
      {"Accuracy", acc},
      {"Cookie", cookie},
    ]

    performance_url = Application.get_env(:trucksu, :performance_url)
    case HTTPoison.post performance_url <> "/acc", {:form, form_data} do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Poison.decode(body) do
          {:ok, %{} = result} ->
            {:ok, result}
          something ->
            Logger.error "Failed to decode max performance json"
            Logger.error inspect(body, limit: :infinity)
            Logger.error inspect something
            {:error, :json_error}
        end
      {:error, error} ->
        Logger.error "Failed to calculate max pp: #{inspect error}"
        {:error, :performance_error}
    end
  end
end

