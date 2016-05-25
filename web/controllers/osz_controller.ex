defmodule Trucksu.OszController do
  use Trucksu.Web, :controller
  require Logger

  plug Trucksu.Plugs.EnsureOsuClientAuthenticated

  def download(conn, %{"beatmapset_id" => beatmapset_id, "u" => username, "h" => password_md5}) do
    {beatmapset_id, _} = Integer.parse(beatmapset_id)

    bucket = Application.get_env(:trucksu, :osz_file_bucket)
    object = "#{beatmapset_id}.osz"
    case ExAws.S3.head_object(bucket, object) do
      {:error, {:http_error, 404, _}} ->
        # TODO: Query params
        Logger.warn "Downloading beatmapset #{beatmapset_id} from osu!"
        ExStatsD.increment "osu.osz_downloads.attempted"
        osu_username = Application.get_env(:trucksu, :osu_username)
        osu_password_md5 = Application.get_env(:trucksu, :osu_password_md5)
        response = HTTPoison.get("https://osu.ppy.sh/d/#{beatmapset_id}", [], follow_redirect: true, params: [{"u", osu_username}, {"h", osu_password_md5}])
        case response do
          {:ok, %HTTPoison.Response{body: osz_file_content, headers: headers} = resp} ->
            Logger.debug inspect resp
            if byte_size(osz_file_content) == 0 do
              Logger.error "Downloaded beatmapset #{beatmapset_id} from osu!, but the .osz is empty!"
              html(conn, "")
            else
              Logger.warn "Downloaded beatmapset #{beatmapset_id} from osu!"
              ExStatsD.increment "osu.osz_downloads.succeeded"

              content_type = Enum.find(headers, &(elem(&1, 0) == "Content-Type")) |> elem(1)
              content_length = Enum.find(headers, &(elem(&1, 0) == "Content-Length")) |> elem(1)
              content_disposition = Enum.find(headers, &(elem(&1, 0) == "Content-Disposition")) |> elem(1)
              opts = [content_type: content_type, content_length: content_length, content_disposition: content_disposition]
              # TODO: Multipart upload
              case ExAws.S3.put_object(bucket, object, osz_file_content, opts) do
                {:ok, _} ->
                  Logger.warn "Put beatmapset #{beatmapset_id} to S3"
                  case ExAws.S3.presigned_url(:get, bucket, object) do
                    {:ok, url} ->
                      redirect(conn, external: url)
                    {:error, error} ->
                      Logger.error "Failed to generate presigned url for beatmapset #{beatmapset_id} : #{inspect error}"
                      html(conn, "")
                  end
                {:error, error} ->
                  Logger.error "Failed to put beatmapset #{beatmapset_id} to S3: #{inspect error}"
                  html(conn, "")
              end
            end
          {:error, error} ->
            Logger.error "Failed to download beatmapset #{beatmapset_id} from osu!: #{inspect error}"
            html(conn, "")
        end

      {:ok, _} ->
        case ExAws.S3.presigned_url(:get, bucket, object) do
          {:ok, url} ->
            redirect(conn, external: url)
          {:error, error} ->
            Logger.error "Failed to generate presigned url for beatmapset #{beatmapset_id} : #{inspect error}"
            html(conn, "")
        end
    end
  end
end

