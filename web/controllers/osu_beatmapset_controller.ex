defmodule Trucksu.OsuBeatmapsetController do
  use Trucksu.Web, :controller
  alias Trucksu.{
    OsuBeatmap,
  }

  def index(conn, %{"beatmap_id" => beatmap_id}) do
    beatmap = Repo.one! from ob in OsuBeatmap,
      join: obs in assoc(ob, :beatmapset),
      join: obs_ob in assoc(obs, :beatmaps),
      left_join: sc in assoc(obs_ob, :scores),
      left_join: u in assoc(sc, :user),
      where: ob.id == ^beatmap_id,
      order_by: [asc: obs_ob.difficultyrating],
      preload: [beatmapset: {obs, [beatmaps: {obs_ob, [scores: {sc, [user: u]}]}]}]

    render(conn, "beatmapset.json", beatmapset: beatmap.beatmapset)
  end
end

