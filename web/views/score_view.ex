defmodule Trucksu.ScoreView do
  use Trucksu.Web, :view

  def render("response.raw", %{data: data}), do: data
end

