defmodule Trucksu.OsuBeatmapFileFetcher do
  require Logger
  alias Trucksu.OsuBeatmapFetcher

  def fetch(beatmap_id) when is_integer(beatmap_id) do
    with {:ok, osu_beatmap} <- OsuBeatmapFetcher.fetch(beatmap_id),
         do: fetch_with_beatmap(osu_beatmap)
  end

  def fetch(file_md5) when is_binary(file_md5) do
    with {:ok, osu_beatmap} <- OsuBeatmapFetcher.fetch(file_md5),
         do: fetch_with_beatmap(osu_beatmap)
  end

  defp fetch_with_beatmap(osu_beatmap) do
    bucket = Application.get_env(:trucksu, :beatmap_file_bucket)
    case ExAws.S3.get_object(bucket, osu_beatmap.file_md5) do
      {:error, {:http_error, 404, _}} ->
        case download_osu_file(osu_beatmap.id) do
          {:ok, osu_file_content} ->
            # TODO: Need to verify beatmap.file_md5 is the same as osu_file_content hash
            case ExAws.S3.put_object(bucket, osu_beatmap.file_md5, osu_file_content) do
              {:ok, _} ->
                {:ok, osu_file_content}
              {:error, error} ->
                Logger.error "Failed to put beatmap #{osu_beatmap.file_md5} to S3: #{inspect error}"
                {:error, error}
            end
            {:ok, osu_file_content}

          {:error, error} ->
            Logger.error "Failed download of beatmap file #{osu_beatmap.file_md5}: #{inspect error}"
            {:error, error}
        end
      {:ok, %{body: osu_file_content}} ->
        {:ok, osu_file_content}
      {:error, error} ->
        Logger.error "Failed to check if beatmap file #{osu_beatmap.file_md5} exists in S3: #{inspect error}"
        {:error, error}
    end
  end

  defp download_osu_file(beatmap_id, tries_remaining \\ 3)

  defp download_osu_file(_beatmap_id, 0) do
    {:error, :osu_file_download_error}
  end

  defp download_osu_file(beatmap_id, tries_remaining) do
    url = "https://osu.ppy.sh/osu/#{beatmap_id}"
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{body: osu_file_content}} when byte_size(osu_file_content) > 0 ->
        {:ok, osu_file_content}

      {:ok, response} ->
        Logger.error "Received empty osu file content when fetching osu file for beatmap id #{beatmap_id}: #{inspect response}"
        {:error, :unknown_osu_file_response}

      {:error, error} ->
        Logger.error "Error when fetching osu file for beatmap id #{beatmap_id}: #{inspect error}"
        download_osu_file(beatmap_id, tries_remaining - 1)
    end
  end
end

