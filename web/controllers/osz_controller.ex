defmodule Trucksu.OszController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.OsuOszFetcher

  @bucket Application.get_env(:trucksu, :osz_file_bucket)

  # TODO: If no username/password is specified, redirect to Trucksu website to allow for download
  # plug Trucksu.Plugs.EnsureOsuClientAuthenticated when action == :osu_client_download
  # plug Guardian.Plug.EnsureAuthenticated, [handler: Trucksu.SessionController] when action == :download

  def download(conn, %{"beatmapset_id" => beatmapset_id, "u" => _username, "h" => _password_md5}) do
    {beatmapset_id, _} = Integer.parse(beatmapset_id)

    # TODO: Rate limit
    # user = conn.assigns[:user]

    case OsuOszFetcher.fetch(beatmapset_id) do
      {:ok, headers, osz_file_content} ->
        send_osz(conn, headers, osz_file_content)
      {:error, _reason} ->
        html(conn, "")
    end
  end

  def download(conn, %{"beatmapset_id" => beatmapset_id}) do
    {beatmapset_id, _} = Integer.parse(beatmapset_id)

    # TODO: Rate limit
    # user = Guardian.Plug.current_resource(conn)

    has_task = Task.async(fn -> OsuOszFetcher.has?(beatmapset_id) end)
    fetch_task = Task.async(fn ->
      case OsuOszFetcher.fetch(beatmapset_id) do
        {:ok, headers, osz_file_content} ->
          send_osz(conn, headers, osz_file_content)
        {:error, :no_content_length} ->
          json(conn, %{"ok" => false, "detail" => "Beatmap is no longer available for download (probably due to copyright)"})
        {:error, _reason} ->
          json(conn, %{"ok" => false})
      end
    end)

    if Task.await(has_task) do
      Task.shutdown(fetch_task)
      object = "#{beatmapset_id}.osz"
      case ExAws.S3.presigned_url(:get, @bucket, object) do
        {:ok, url} ->
          redirect(conn, external: url)
        {:error, error} ->
          Logger.error "Failed to generate presigned url for beatmapset #{beatmapset_id} : #{inspect error}"
          json(conn, %{"ok" => false})
      end
    else
      # wait for 30 seconds
      Task.await(fetch_task, 30_000)
    end
  end

  defp send_osz(conn, headers, osz_file_content) do
    content_type = Enum.find(headers, &(elem(&1, 0) == "Content-Type")) |> elem(1)
    content_length = Enum.find(headers, &(elem(&1, 0) == "Content-Length")) |> elem(1)
    content_disposition = Enum.find(headers, &(elem(&1, 0) == "Content-Disposition")) |> elem(1)

    # TODO: Check if additional headers are needed

    conn
    |> put_resp_header("Content-Type", content_type)
    |> put_resp_header("Content-Length", content_length)
    |> put_resp_header("Content-Disposition", content_disposition)
    |> send_resp(200, osz_file_content)
  end
end

