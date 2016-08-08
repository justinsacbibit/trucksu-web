defmodule Trucksu.PerformanceGraph.Server do
  @moduledoc """
  Provides the interface for retrieving performance graphs.

  Handles saving/caching/recalculation of graphs when necessary.
  """
  require Logger
  alias Trucksu.PerformanceGraph.Calculator

  @cache_name :trucksu_cache

  def get(user_id, game_mode \\ 0) do
    # TODO: Use Phoenix.PubSub (or another form of pubsub) to invalidate the cache
    {status, graph} = Cachex.get(@cache_name, key(user_id, game_mode), fallback: fn(_key) ->
      Calculator.compute_graph(user_id, game_mode)
    end)
    case status do
      :loaded ->
        Logger.info "Performance graph cache miss"
        ExStatsD.increment("performance_graph.cache.misses")
      :ok ->
        Logger.info "Performance graph cache hit"
        ExStatsD.increment("performance_graph.cache.hits")
    end
    graph
  end

  def invalidate(user_id, game_mode \\ 0) do
    Cachex.del(@cache_name, key(user_id, game_mode))
  end

  defp key(user_id, game_mode) do
    "performance_graph-#{user_id}/#{game_mode}"
  end
end
