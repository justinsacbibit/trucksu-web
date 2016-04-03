defmodule Trucksu.CurrentUserView do
  use Trucksu.Web, :view

  def render("show.json", %{user: user}) do
    user
  end
end

