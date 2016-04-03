defmodule Trucksu.AvatarController do
  use Trucksu.Web, :controller

  defp avatar_path(filename) do
    # TODO: Figure out how not to hardcode the path
    "apps/trucksu/priv/static/images/" <> filename
  end

  def show(conn, _params) do
    # TODO: Return the correct avatar based on params["user_id"]
    path = avatar_path("default_avatar.jpg")
    Plug.Conn.send_file(conn, 200, path)
  end
end

