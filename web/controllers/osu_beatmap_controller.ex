defmodule Trucksu.OsuBeatmapController do
  use Trucksu.Web, :controller
  alias Trucksu.{
    OsuBeatmap,
  }

  def show(conn, %{"beatmap_id" => beatmap_id}) do
    beatmap = Repo.one! from ob in OsuBeatmap,
      join: obs in assoc(ob, :beatmapset),
      join: obsb in assoc(obs, :beatmaps),
      left_join: sc in assoc(ob, :scores),
      left_join: u in assoc(sc, :user),
      where: ob.id == ^beatmap_id,
      preload: [beatmapset: {obs, [beatmaps: obsb]}, scores: {sc, [user: u]}]

    render(conn, "beatmap.json", beatmap: beatmap)
  end
end

