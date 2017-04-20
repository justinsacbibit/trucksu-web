defmodule Trucksu.OsuOszFetcher do
  require Logger
  alias Trucksu.OsuBeatmapsetFetcher

  @bucket Application.get_env(:trucksu, :osz_file_bucket)
  @osu_username Application.get_env(:trucksu, :osu_username)
  @osu_password_md5 Application.get_env(:trucksu, :osu_password_md5)

  defp object_name(beatmapset_id), do: "#{beatmapset_id}.osz"

  @doc """
  Checks if a beatmapset is present in S3.

  Useful for returning an presigned S3 URL.
  """
  def has?(beatmapset_id) do
    case ExAws.S3.head_object(@bucket, object_name(beatmapset_id)) |> ExAws.request do
      {:ok, _} ->
        true
      _ ->
        false
    end
  end

  def fetch(beatmapset_id) do

    # Update our local copy of the beatmapset. This function will take care of
    # deleting an outdated .osz we might have.
    OsuBeatmapsetFetcher.fetch(beatmapset_id)

    # TODO: Novideo

    object = object_name(beatmapset_id)
    case ExAws.S3.get_object(@bucket, object) |> ExAws.request do
      {:error, {:http_error, 404, _}} ->
        Logger.warn "Downloading beatmapset #{beatmapset_id} from osu!"
        ExStatsD.increment "osu.osz_downloads.attempted"
        response = HTTPoison.get("https://osu.ppy.sh/d/#{beatmapset_id}", [], follow_redirect: true, params: [{"u", @osu_username}, {"h", @osu_password_md5}], timeout: 30_000, recv_timeout: 30_000)
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
                Task.start(fn ->
                  Logger.warn "Downloaded beatmapset #{beatmapset_id} from osu!"
                  ExStatsD.increment "osu.osz_downloads.succeeded"

                  content_type = Enum.find(headers, &(elem(&1, 0) == "Content-Type")) |> elem(1)
                  content_length = content_length_header |> elem(1)
                  content_disposition = Enum.find(headers, &(elem(&1, 0) == "Content-Disposition")) |> elem(1)
                  opts = [content_type: content_type, content_length: content_length, content_disposition: content_disposition]
                  # TODO: Multipart upload
                  case ExAws.S3.put_object(@bucket, object, osz_file_content, opts) |> ExAws.request do
                    {:ok, _} ->
                      Logger.debug "Put beatmapset #{beatmapset_id} to S3"
                    {:error, error} ->
                      Logger.error "Failed to put beatmapset #{beatmapset_id} to S3: #{inspect error}"
                  end
                end)

                {:ok, headers, osz_file_content}
              else
                Logger.info "Downloaded beatmapset #{beatmapset_id} from osu!, but there is no Content-Length header!"
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

