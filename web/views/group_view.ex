defmodule Trucksu.GroupView do
  use Trucksu.Web, :view

  def render("show.json", %{group: group}) do
    %{
      id: group.id,
      name: group.name,
    }
  end
end

