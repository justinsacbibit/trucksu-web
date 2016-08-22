defmodule Trucksu.MeController do
  use Trucksu.Web, :controller
  alias Trucksu.Userpage

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    Trucksu.UserController.show(conn, %{"id" => "#{user.id}"})
  end

  def upload_userpage(conn, %{"userpage" => userpage}) do
    user = Guardian.Plug.current_resource(conn)

    Userpage.Manager.upload(user.id, userpage)

    conn
    |> json(%{
      "ok" => true,
    })
  end
end
