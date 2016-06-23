defmodule Trucksu.OsuOszFetcher do
  require Logger
  alias Trucksu.OsuBeatmapsetFetcher

  def fetch(beatmapset_id) do

    # Update our local copy of the beatmapset. This function will take care of
    # deleting an outdated .osz we might have.
    OsuBeatmapsetFetcher.fetch(beatmapset_id)

    # TODO: Novideo

    bucket = Application.get_env(:trucksu, :osz_file_bucket)
    object = "#{beatmapset_id}.osz"
    case ExAws.S3.get_object(bucket, object) do
      {:error, {:http_error, 404, _}} ->
        Logger.warn "Downloading beatmapset #{beatmapset_id} from osu!"
        ExStatsD.increment "osu.osz_downloads.attempted"
        osu_username = Application.get_env(:trucksu, :osu_username)
        osu_password_md5 = Application.get_env(:trucksu, :osu_password_md5)
        response = HTTPoison.get("https://osu.ppy.sh/d/#{beatmapset_id}", [], follow_redirect: true, params: [{"u", osu_username}, {"h", osu_password_md5}])
        Logger.debug inspect response
        case response do
          {:ok, %HTTPoison.Response{body: osz_file_content, headers: headers} = resp} ->
            Logger.debug inspect resp
            if byte_size(osz_file_content) == 0 do
              Logger.error "Downloaded beatmapset #{beatmapset_id} from osu!, but the .osz is empty!"
              {:error, :osz_empty}
            else
              content_length_header = Enum.find(headers, &(elem(&1, 0) == "Content-Length"))

              if content_length_header do
                Logger.warn "Downloaded beatmapset #{beatmapset_id} from osu!"
                ExStatsD.increment "osu.osz_downloads.succeeded"

                content_type = Enum.find(headers, &(elem(&1, 0) == "Content-Type")) |> elem(1)
                content_length = content_length_header |> elem(1)
                content_disposition = Enum.find(headers, &(elem(&1, 0) == "Content-Disposition")) |> elem(1)
                opts = [content_type: content_type, content_length: content_length, content_disposition: content_disposition]
                # TODO: Multipart upload
                case ExAws.S3.put_object(bucket, object, osz_file_content, opts) do
                  {:ok, _} ->
                    Logger.warn "Put beatmapset #{beatmapset_id} to S3"
                    {:ok, headers, osz_file_content}
                  {:error, error} ->
                    Logger.error "Failed to put beatmapset #{beatmapset_id} to S3: #{inspect error}"
                    {:error, :s3_error}
                end
              else
                Logger.error "Downloaded beatmapset #{beatmapset_id} from osu!, but there is no Content-Length header!"
                {:error, :no_content_length}
              end
            end
          {:error, error} ->
            Logger.error "Failed to download beatmapset #{beatmapset_id} from osu!: #{inspect error}"
            {:error, :osu_download_error}
        end

      {:ok, %{body: osz_file_content, headers: headers}} ->
        {:ok, headers, osz_file_content}
    end
  end
end

