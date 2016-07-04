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
      groups: for group <- user.groups do
        %{
          id: group.id,
          name: group.name,
        }
      end,
    }
  end
end

