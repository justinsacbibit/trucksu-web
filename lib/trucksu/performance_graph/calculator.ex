defmodule Trucksu.PerformanceGraph.Calculator do
  @moduledoc """
  Does the work of calculating a performance graph.

  Retrieves data from the DB and transforms it, but does not handle saving.
  """
  alias Trucksu.{
    Repo,
    Score,

    Performance,
  }
  import Ecto.Query, only: [from: 2]

  def compute_graph(user_id, game_mode \\ 0) do
    query = from s in Score,
      where: s.user_id == ^user_id
        and s.game_mode == ^game_mode
        and s.pass
        and not is_nil(s.pp),
      order_by: [desc: s.pp]
    scores = Repo.all(query)

    compute_graph_with_scores(scores)
  end

  @doc """
  Requires that the scores be sorted by pp, descending.
  """
  def compute_graph_with_scores(scores) do
    dates = scores
    |> Enum.map(fn(score) -> String.slice(score.time, 0..5) end)
    |> Enum.uniq

    points = dates
    |> Enum.sort
    |> Enum.map(fn(date) ->
      scores_on_or_before_date = Enum.filter(scores, fn(score) ->
        String.slice(score.time, 0..5) <= date
      end)

      pp = Performance.calculate_stats_for_scores(scores_on_or_before_date)
      |> Keyword.get(:pp)

      date = Timex.parse!(date, "{YY}{0M}{0D}")
      {date, pp}
    end)

    # TODO: Interpolate?

    points
  end
end
