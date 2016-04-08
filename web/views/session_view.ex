defmodule Trucksu.SessionView do
  use Trucksu.Web, :view

  def render("show.json", %{jwt: jwt, user: user}) do
    %{
      jwt: jwt,
      user: user,
    }
  end

  def render("error.json", _assigns) do
    # TODO: Render a better error message based on any assigns
    %{error: "Invalid email or password"}
  end

  def render("delete.json", _) do
    %{ok: true}
  end

  def render("forbidden.json", %{error: error}) do
    %{error: error}
  end
end

