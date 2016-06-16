defmodule Trucksu.AvatarController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.FileRepository

  def show(conn, %{"user_id" => user_id}) do
    case user_id do
      "-1" ->
        send_default_avatar(conn)
      _ ->
        case FileRepository.get_file(:avatar_file_bucket, user_id) do
          {:error, :not_found} ->
            send_default_avatar(conn)

          {:error, error} ->
            Logger.error "Failed to get avatar for user id #{user_id}"
            Logger.error inspect error
            send_default_avatar(conn)

          {:ok, avatar_file_content} ->
            Plug.Conn.send_resp(conn, 200, avatar_file_content)
        end
    end
  end

  defp send_default_avatar(conn) do
    default_path = "web/static/images/default_avatar.jpg"
    Plug.Conn.send_file(conn, 200, default_path)
  end
end

