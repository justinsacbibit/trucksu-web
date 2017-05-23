defmodule Trucksu.CurrentUserController do
  use Trucksu.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Trucksu.SessionController
  plug :check_user_plug

  def check_user_plug(%Plug.Conn{params: params} = conn, _opts) do
    user = Guardian.Plug.current_resource(conn)
    if is_nil(user) do
      conn |> halt |> Trucksu.SessionController.unauthenticated(params)
    else
      conn
    end
  end

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)
      |> Repo.preload(:groups)

    conn
    |> put_status(:ok)
    |> render("show.json", user: user)
  end
end

