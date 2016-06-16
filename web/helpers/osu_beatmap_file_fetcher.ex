defmodule Trucksu.OsuBeatmapFileFetcher do
  require Logger
  alias Trucksu.{FileRepository, OsuBeatmapFetcher}

  def fetch(beatmap_id) when is_integer(beatmap_id) do
    with {:ok, beatmap} <- OsuBeatmapFetcher.fetch(beatmap_id),
         do: fetch_with_beatmap(beatmap)
  end

  def fetch(file_md5) when is_binary(file_md5) do
    with {:ok, beatmap} <- OsuBeatmapFetcher.fetch(file_md5),
         do: fetch_with_beatmap(beatmap)
  end

  defp fetch_with_beatmap(beatmap) do
    bucket = :beatmap_file_bucket
    case FileRepository.get_file(bucket, beatmap.file_md5) do
      {:error, :not_found} ->
        case download_osu_file(beatmap.beatmap_id) do
          {:ok, osu_file_content} ->
            # TODO: Need to verify beatmap.file_md5 is the same as osu_file_content hash
            case FileRepository.put_file(bucket, beatmap.file_md5, osu_file_content) do
              :ok ->
                Logger.warn "Put beatmap #{beatmap.file_md5} in repository: #{bucket}"
              {:error, error} ->
                Logger.error "Failed to put beatmap #{beatmap.file_md5} to repository: #{inspect error}"
            end
            {:ok, osu_file_content}

          {:error, error} ->
            Logger.error "Failed to download .osu file for beatmap id #{beatmap.beatmap_id}"
            Logger.error inspect error
            {:error, error}
        end

      {:error, error} ->
        Logger.error "Failed to check if .osu file exists for beatmap md5 #{beatmap.file_md5}"
        Logger.error inspect error
        {:error, error}

      {:ok, osu_file_content} ->
        {:ok, osu_file_content}
    end
  end

  defp download_osu_file(beatmap_id) do
    url = "https://osu.ppy.sh/osu/#{beatmap_id}"
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{body: osu_file_content}} ->
        {:ok, osu_file_content}

      {:error, response} ->
        Logger.error "Received unknown response when fetching osu file for beatmap id #{beatmap_id}"
        {:error, :unknown_osu_file_response}
    end
  end
end

