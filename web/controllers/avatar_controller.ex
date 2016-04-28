defmodule Trucksu.AvatarController do
  use Trucksu.Web, :controller

  defp avatar_path(filename) do
    "web/static/images/" <> filename
  end

  def show(conn, %{"user_id" => user_id}) do
    # TODO: Return the correct avatar based on params["user_id"]
    # TODO: Use S3 for storing the images
    filename = case user_id do
      "8" -> "unsaturated.jpg"
      "6" -> "wow.png"
      _ -> "default_avatar.jpg"
    end
    path = avatar_path(filename)
    Plug.Conn.send_file(conn, 200, path)
  end
end

