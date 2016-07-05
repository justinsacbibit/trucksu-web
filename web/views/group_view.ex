defmodule Trucksu.GroupView do
  use Trucksu.Web, :view

  def render("show.json", %{group: %{users: %Ecto.Association.NotLoaded{}} = group}) do
    %{
      id: group.id,
      name: group.name,
    }
  end
  def render("show.json", %{group: group}) do
    IO.inspect group
    %{
      id: group.id,
      name: group.name,
      users: render_many(group.users, Trucksu.UserView, "show.json")
    }
  end

  def render("index.json", %{groups: groups}) do
    render_many(groups, __MODULE__, "show.json")
  end
end

