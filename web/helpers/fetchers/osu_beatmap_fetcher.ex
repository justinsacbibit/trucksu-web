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
    OsuBeatmap.get(identifier)
    |> Repo.one
    |> handle_osu_beatmap(identifier)
  end

  defp handle_osu_beatmap(nil, identifier) do
    # 1 call every 2 hours
    rate_limit = ExRated.check_rate("beatmap-#{identifier}", 7_200_000, 1)
    case rate_limit do
      {:error, _} ->
        {:error, :beatmap_not_found}
      _ ->
        fetch_with_identifier(identifier)
    end
  end
  defp handle_osu_beatmap(osu_beatmap, _identifier) do
    OsuBeatmapsetFetcher.fetch(osu_beatmap.beatmapset_id)
    {:ok, osu_beatmap}
  end

  defp get_params(beatmap_id) when is_integer(beatmap_id) do
    [b: beatmap_id]
  end
  defp get_params(file_md5) when is_binary(file_md5) do
    [h: file_md5]
  end

  defp fetch_with_identifier(identifier) do
    params = get_params(identifier)
    osu_api_call_result = case Osu.get_beatmaps!(params) do
      %HTTPoison.Response{body: [beatmap_data]} ->

        {:ok, beatmap_data}
      %HTTPoison.Response{body: []} ->
        Logger.info "Beatmap not found for params #{inspect params}"
        {:error, :beatmap_not_found}
      response ->
        Logger.error "Received unexpected response when attempting to fetch beatmap from osu! API with params #{inspect params}, response: #{inspect response}"
        {:error, :unknown}
    end

    case osu_api_call_result do
      {:ok, beatmap_map} ->
        OsuBeatmapsetFetcher.fetch(beatmap_map["beatmapset_id"])
        case OsuBeatmap.get(identifier) |> Repo.one do
          nil ->
            {:error, :unknown_error}
          osu_beatmap ->
            {:ok, osu_beatmap}
        end
      {:error, error} ->
        {:error, error}
    end
  end
end
