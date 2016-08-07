defmodule Trucksu.GraphView do
  use Trucksu.Web, :view

  def render("show.json", %{points: points}) do
    render_many(points, __MODULE__, "point.json", as: :point)
  end

  def render("point.json", %{point: {date, pp}}) do
    %{
      date: Timex.format!(date, "{ISOdate}"),
      pp: pp,
    }
  end
end
