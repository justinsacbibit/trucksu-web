defmodule Trucksu.GraphView do
  use Trucksu.Web, :view

  def render("show.json", %{points: points}) do
    render_many(points, __MODULE__, "point.json", as: :point)
  end

  def render("point.json", %{point: {date, value}}) do
    %{
      date: Timex.format!(date, "{ISOdate}"),
      unix_time: Timex.format!(date, "{s-epoch}") |> Integer.parse |> elem(0),
      value: value,
    }
  end
end
