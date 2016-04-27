defmodule Trucksu.OsuBeatmapFileFetcher do
  require Logger
  alias Trucksu.OsuBeatmapFetcher

  def fetch(beatmap_id) when is_integer(beatmap_id) do
    with {:ok, beatmap} <- OsuBeatmapFetcher.fetch(beatmap_id),
         do: fetch_with_beatmap(beatmap)
  end

  def fetch(file_md5) when is_binary(file_md5) do
    with {:ok, beatmap} <- OsuBeatmapFetcher.fetch(file_md5),
         do: fetch_with_beatmap(beatmap)
  end

  defp fetch_with_beatmap(beatmap) do
    bucket = Application.get_env(:trucksu, :beatmap_file_bucket)
    case ExAws.S3.get_object(bucket, beatmap.file_md5) do
      {:error, {:http_error, 404, _}} ->
        case download_osu_file(beatmap.beatmap_id) do
          {:ok, osu_file_content} ->
            case ExAws.S3.put_object(bucket, beatmap.file_md5, osu_file_content) do
              {:ok, _} ->
                :ok
              error ->
                Logger.error "Failed to put beatmap #{beatmap.file_md5} to S3: #{inspect error}"
            end
            {:ok, osu_file_content}

          error ->
            error
        end
      {:ok, %{body: osu_file_content}} ->
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

