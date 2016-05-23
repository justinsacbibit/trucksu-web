defmodule Trucksu.OsuBeatmapFetcher do
  alias Trucksu.{
    OsuBeatmapsetFetcher,

    Osu,
    OsuBeatmap,
    Repo,
  }
  require Logger

  @doc """
  Attempts to load an OsuBeatmap from the database. If it doesn't exist,
  attempts to retrieve it from the official osu! API, insert it into the
  database, then return it.
  """
  def fetch(identifier) do
    # 1 call every 2 hours
    rate_limit = ExRated.check_rate("beatmap-#{identifier}", 7_200_000, 1)

    case rate_limit do
      {:error, _} ->
        {:error, :rate_limit}
      _ ->
        actually_fetch(identifier)
    end
  end

  defp actually_fetch(identifier) do
    case beatmap_from_repo(identifier) do
      nil ->
        case fetch_with_identifier(identifier) do
          {:ok, beatmap_map} ->
            OsuBeatmapsetFetcher.fetch(beatmap_map["beatmapset_id"])
            case beatmap_from_repo(identifier) do
              nil ->
                {:error, :unknown_error}
              osu_beatmap ->
                {:ok, osu_beatmap}
            end
          {:error, error} ->
            {:error, error}
        end
      osu_beatmap ->
        OsuBeatmapsetFetcher.fetch(osu_beatmap.beatmapset_id)
        {:ok, osu_beatmap}
    end
  end

  defp beatmap_from_repo(beatmap_id) when is_integer(beatmap_id) do
    Repo.get OsuBeatmap, beatmap_id
  end
  defp beatmap_from_repo(file_md5) when is_binary(file_md5) do
    Repo.get_by OsuBeatmap, file_md5: file_md5
  end

  defp fetch_with_identifier(beatmap_id) when is_integer(beatmap_id) do
    fetch_with_params(b: beatmap_id)
  end
  defp fetch_with_identifier(file_md5) when is_binary(file_md5) do
    fetch_with_params(h: file_md5)
  end

  defp fetch_with_params(params) do
    case Osu.get_beatmaps!(params) do
      %HTTPoison.Response{body: [beatmap_data]} ->

        {:ok, beatmap_data}
      %HTTPoison.Response{body: []} ->
        Logger.error "Beatmap not found for params #{inspect params}"
        {:error, :beatmap_not_found}
      response ->
        Logger.error "Received unexpected response when attempting to fetch beatmap from osu! API with params #{inspect params}"
        Logger.error inspect(response)
        {:error, :unknown}
    end
  end
end
