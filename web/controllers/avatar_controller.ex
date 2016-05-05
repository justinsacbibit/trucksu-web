defmodule Trucksu.AvatarController do
  use Trucksu.Web, :controller

  def show(conn, %{"user_id" => user_id}) do
    default_path = "web/static/images/default_avatar.jpg"
    case user_id do
      "-1" ->
        Plug.Conn.send_file(conn, 200, default_path)
      _ ->
        bucket = Application.get_env(:trucksu, :avatar_file_bucket)
        case ExAws.S3.get_object(bucket, user_id) do
          {:error, {:http_error, 404, _}} ->

            Plug.Conn.send_file(conn, 200, default_path)

          {:ok, %{body: avatar_file_content}} ->
            Plug.Conn.send_resp(conn, 200, avatar_file_content)
        end
    end
  end
end

