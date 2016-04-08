defmodule Trucksu.OpsView do
  use Trucksu.Web, :view

  def render("restart.json", _) do
    %{ok: true}
  end
end
