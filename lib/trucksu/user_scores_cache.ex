defmodule Trucksu.UserScoresCache do
  alias Trucksu.{
    Repo,
    Score,
    UserStats,
  }
  require Logger
  import Ecto.Query, only: [from: 2]

  @cache_name :trucksu_cache

  def get(user_id, game_mode) do
    calculate(user_id, game_mode)
  end
  # TODO: Don't cache first place scores
  #def get(user_id, game_mode) do
  #  # TODO: Use Phoenix.PubSub (or another form of pubsub) to invalidate the cache
  #  {status, result} = Cachex.get(@cache_name, key(user_id, game_mode), fallback: fn(_key) ->
  #    calculate(user_id, game_mode)
  #  end, ttl: :timer.hours(7 * 24)) # TODO: First place ranks don't get invalidated
  #  case status do
  #    :loaded ->
  #      Logger.info "User scores cache miss"
  #    :ok ->
  #      Logger.info "User scores cache hit"
  #  end
  #  result
  #end

  def invalidate(user_id, game_mode) do
    Cachex.del(@cache_name, key(user_id, game_mode))
  end

  defp key(user_id, game_mode) do
    "user_scores-#{user_id}/#{game_mode}"
  end

  defp calculate(user_id, game_mode) do
    score_query = from sc in Score,
      where: sc.user_id == ^user_id
        and sc.game_mode == ^game_mode
        and sc.pass
        and not is_nil(sc.pp),
      order_by: [desc: sc.pp]

    scores_task = create_scores_task(score_query)

    query = from sc in score_query,
      join: sc_ in fragment("
        SELECT id
        FROM (
          SELECT
            sc.id,
            user_id,
            sc.game_mode,
            row_number()
            OVER (PARTITION BY sc.file_md5, sc.game_mode
               ORDER BY score DESC) score_rank
          FROM scores sc
          JOIN users u
            on sc.user_id = u.id
          WHERE sc.pass AND NOT u.banned
        ) x
        WHERE user_id = (?) AND score_rank = 1 AND game_mode = (?)
      ", ^user_id, ^game_mode),
        on: sc_.id == sc.id

    first_place_scores_task = create_scores_task(query)

    us_query = from us in UserStats,
      where: us.user_id == ^user_id
        and us.game_mode == ^game_mode
    stats_for_game_mode = Repo.one!(us_query)

    {stats_for_game_mode, Task.await(scores_task), Task.await(first_place_scores_task)}
  end

  defp create_scores_task(query) do
    Task.async(fn ->
      Repo.all(query)
      |> Repo.preload(osu_beatmap: [:beatmapset])
      |> Enum.uniq_by(fn(score) -> score.file_md5 end)
      |> Enum.take(100)
    end)
  end
end
