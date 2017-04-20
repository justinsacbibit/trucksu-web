defmodule Trucksu.ScreenshotController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    Session,

    Screenshot,
  }

  @screenshot_file_bucket Application.get_env(:trucksu, :screenshot_file_bucket)

  plug :authenticate when action in [:create]

  defp authenticate(%Plug.Conn{params: %{"u" => username, "p" => password_md5}} = conn, _) do
    case Session.authenticate(username, password_md5, true) do
      {:error, reason} ->
        Logger.warn "#{username} attempted to upload a screenshot, but was unable to authenticate: #{reason}"
        stop_plug(conn, 403)
      {:ok, user} ->
        assign(conn, :user, user)
    end
  end
  defp authenticate(conn, _) do
    stop_plug(conn, 400)
  end

  def create(conn, %{"ss_file" => %Plug.Upload{path: ss_path}, "v" => _unknown}) do
    {:ok, screenshot_id} = Repo.transaction(fn ->
      user = conn.assigns[:user]
      changeset = Screenshot.new(user.id)
      screenshot = Repo.insert! changeset

      screenshot_file_content = File.read!(ss_path)
      ExAws.S3.put_object!(@screenshot_file_bucket, "#{screenshot.id}", screenshot_file_content) |> ExAws.request

      screenshot.id
    end)

    html(conn, "#{screenshot_id}")
  end

  def show(%Plug.Conn{host: "osu.ppy.sh"} = conn, %{"id" => id}) do
    base = Application.get_env(:trucksu, :screenshots_url)
    redirect conn, external: "#{base}/#{id}"
  end

  def show(conn, %{"id" => id}) do
    case ExAws.S3.get_object(@screenshot_file_bucket, id) |> ExAws.request do
      {:error, {:http_error, 404, _}} ->

        conn
        |> put_status(404)
        |> html("")

      {:ok, %{body: screenshot_file_content}} ->

        conn
        |> Plug.Conn.put_resp_header("content-type", "image/jpeg")
        |> Plug.Conn.put_resp_header("content-transfer-encoding", "binary")
        |> Plug.Conn.send_resp(200, screenshot_file_content)
    end
  end

  defp stop(conn, status_code) do
    conn
    |> put_status(status_code)
    |> html("")
  end

  defp stop_plug(conn, status_code) do
    stop(conn, status_code)
    |> halt
  end
end
