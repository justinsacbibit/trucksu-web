defmodule Trucksu.CurrentUserView do
  use Trucksu.Web, :view
  alias Trucksu.Repo

  def render("show.json", %{user: user}) do
    user = user
    |> Repo.preload(:groups)
    |> Repo.preload(:friends)

    IO.inspect user.friends

    %{
      id: user.id,
      username: user.username,
      email: user.email,
      email_verified: user.email_verified,
      groups: render_many(user.groups, Trucksu.GroupView, "show.json"),
      friends: render_many(user.friends, Trucksu.UserView, "show.json"),
    }
  end
end

