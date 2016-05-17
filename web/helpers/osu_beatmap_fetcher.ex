defmodule Trucksu.OsuBeatmapFetcher do
  alias Trucksu.{Osu, OsuBeatmap, Repo}
  require Logger

  @doc """
  Attempts to load an OsuBeatmap from the database. If it doesn't exist,
  attempts to retrieve it from the official osu! API, insert it into the
  database, then return it.
  """
  def fetch(beatmap_id) when is_integer(beatmap_id) do
    case Repo.get OsuBeatmap, beatmap_id do
      nil ->
        fetch_and_insert(b: beatmap_id)
      osu_beatmap ->
        # TODO: If the beatmap is not ranked or approved, check if it's
        # been updated
        {:ok, osu_beatmap}
    end
  end

  @doc """
  Attempts to load an OsuBeatmap from the database. If it doesn't exist,
  attempts to retrieve it from the official osu! API, insert it into the
  database, then return it.
  """
  def fetch(file_md5) when is_binary(file_md5) do
    case Repo.get_by OsuBeatmap, file_md5: file_md5 do
      nil ->
        fetch_and_insert(h: file_md5)
      osu_beatmap ->
        # TODO: If the beatmap is not ranked or approved, check if it's
        # been updated
        {:ok, osu_beatmap}
    end
  end

  defp fetch_and_insert(params) do
    with {:ok, beatmap_data} <- fetch_with_params(params),
         do: insert(beatmap_data)
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

  defp insert(beatmap_data) do
    beatmap_data = beatmap_data
    |> Map.put("game_mode", beatmap_data["mode"])
    |> Map.delete("mode")
    changeset = OsuBeatmap.changeset(%OsuBeatmap{}, beatmap_data)

    Repo.insert changeset
  end
end
