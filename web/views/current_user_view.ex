defmodule Trucksu.CurrentUserView do
  use Trucksu.Web, :view
  alias Trucksu.Repo

  def render("show.json", %{user: user}) do
    user = Repo.preload(user, :groups)
    %{
      id: user.id,
      username: user.username,
      email: user.email,
      email_verified: user.email_verified,
      groups: render_many(user.groups, Trucksu.GroupView, "show.json"),
    }
  end
end

