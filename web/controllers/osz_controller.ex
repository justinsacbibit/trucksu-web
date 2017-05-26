defmodule Trucksu.OszController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{Env, OsuOszFetcher}

  # TODO: If no username/password is specified, redirect to Trucksu website to allow for download
  # plug Trucksu.Plugs.EnsureOsuClientAuthenticated when action == :osu_client_download
  # plug Guardian.Plug.EnsureAuthenticated, [handler: Trucksu.SessionController] when action == :download

  def download(conn, %{"beatmapset_id" => beatmapset_id, "u" => _username, "h" => _password_md5}) do
    Logger.info "download from osu! client"
    {beatmapset_id, _} = Integer.parse(beatmapset_id)

    # TODO: Rate limit
    # user = conn.assigns[:user]

    case OsuOszFetcher.fetch(beatmapset_id) do
      {:ok, headers, osz_file_content} ->
#        send_osz(conn, headers, osz_file_content)
        handle_already_downloaded(nil, beatmapset_id, conn)
      {:error, _reason} ->
        html(conn, "")
    end
  end

  def download(conn, %{"beatmapset_id" => beatmapset_id}) do
    {beatmapset_id, _} = Integer.parse(beatmapset_id)

    # TODO: Rate limit
    # user = Guardian.Plug.current_resource(conn)

    already_downloaded_task = Task.async(fn ->
      OsuOszFetcher.has?(beatmapset_id)
    end)

    fetch_task = Task.async(fn ->
      OsuOszFetcher.fetch(beatmapset_id)
    end)

    already_downloaded = Task.await(already_downloaded_task)

    if already_downloaded do
      handle_already_downloaded(fetch_task, beatmapset_id, conn)
    else
      wait_for_fetch_then_send(fetch_task, beatmapset_id, conn)
    end
  end

  defp handle_already_downloaded(fetch_task, beatmapset_id, conn) do
    if not is_nil(fetch_task) do
      Task.shutdown(fetch_task)
    end
    object = "#{beatmapset_id}.osz"
    case ExAws.S3.presigned_url(%{}, :get, Env.osz_file_bucket(), object) |> ExAws.request do
      {:ok, url} ->
        redirect(conn, external: url)
      {:error, error} ->
        Logger.error "Failed to generate presigned url for beatmapset #{beatmapset_id} : #{inspect error}"
        json(conn, %{"ok" => false})
    end
  end

  defp wait_for_fetch_then_send(fetch_task, beatmapset_id, conn) do
    Logger.info "Fetching beatmapset with id #{beatmapset_id}, since we do not already have it downloaded"
    # wait for 30 seconds
    case Task.await(fetch_task, 30_000) do
      {:ok, headers, osz_file_content} ->
        send_osz(conn, headers, osz_file_content)
      {:error, :no_content_length} ->
        json(conn, %{"ok" => false, "detail" => "Beatmap is no longer available for download (probably due to copyright)"})
      {:error, _reason} ->
        json(conn, %{"ok" => false})
    end
  end

  defp send_osz(conn, original_osu_headers, osz_file_content) do
    content_type = find_header(original_osu_headers, "Content-Type")
    content_length = find_header(original_osu_headers, "Content-Length")
    content_disposition = find_header(original_osu_headers, "Content-Disposition")

    conn
    |> put_resp_header("Content-Type", content_type)
    |> put_resp_header("Content-Length", content_length)
    |> put_resp_header("Content-Disposition", content_disposition)
    |> send_resp(200, osz_file_content)
  end

  defp find_header(headers, header_to_find) do
    Enum.find(headers, &(elem(&1, 0) == header_to_find)) |> elem(1)
  end
end

