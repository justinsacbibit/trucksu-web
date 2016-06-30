defmodule Trucksu.CurrentUserView do
  use Trucksu.Web, :view

  def render("show.json", %{user: user}) do
    %{
      id: user.id,
      username: user.username,
      email: user.email,
      email_verified: user.email_verified,
    }
  end
end

