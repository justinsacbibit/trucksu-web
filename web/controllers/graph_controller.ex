defmodule Trucksu.GraphController do
  use Trucksu.Web, :controller
  alias Trucksu.PerformanceGraph

  def show_pp(conn, %{"id" => id}) do
    {id, ""} = Integer.parse(id)
    points = PerformanceGraph.Server.get(id)
    render(conn, "show.json", points: points)
  end
end
