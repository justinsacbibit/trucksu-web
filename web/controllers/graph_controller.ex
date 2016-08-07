defmodule Trucksu.GraphController do
  use Trucksu.Web, :controller
  alias Trucksu.PerformanceGraph

  def show_pp(conn, %{"id" => id}) do
    # TODO: Non-std game modes
    points = PerformanceGraph.Server.get(id)
    render(conn, "show.json", points: points)
  end
end
