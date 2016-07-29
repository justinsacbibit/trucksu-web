defmodule Trucksu.AvatarController do
  use Trucksu.Web, :controller

  @default_path "web/static/images/default_avatar.jpg"
  @avatar_file_bucket Application.get_env(:trucksu, :avatar_file_bucket)

  def show(conn, %{"user_id" => "-1"}) do
    Plug.Conn.send_file(conn, 200, @default_path)
  end
  def show(conn, %{"user_id" => user_id}) do
    case ExAws.S3.get_object(@avatar_file_bucket, user_id) do
      {:error, {:http_error, 404, _}} ->
        conn
        |> put_cache_headers("default-avatar")
        |> Plug.Conn.send_file(200, @default_path)

      {:ok, %{body: avatar_file_content, headers: headers}} ->
        case find_etag(headers) do
          nil ->
            conn
          etag ->
            conn
            |> put_cache_headers(etag)
        end

        conn
        |> Plug.Conn.put_resp_header("content-type", "image/jpeg")
        |> Plug.Conn.put_resp_header("content-transfer-encoding", "binary")
        |> Plug.Conn.send_resp(200, avatar_file_content)
    end
  end

  defp find_etag(headers) do
    case Enum.find(headers, fn({key, _value}) -> key == "ETag" end) do
      {_key, etag} ->
        etag
      _ ->
        nil
    end
  end

  defp put_cache_headers(conn, etag) do
    conn
    |> Plug.Conn.put_resp_header("cache-control", "public, max-age=30")
    |> Plug.Conn.put_resp_header("ETag", etag)
  end
end

