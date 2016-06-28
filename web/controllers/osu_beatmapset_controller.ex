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
      where: ob.id == ^beatmap_id
        and (is_nil(sc.id) or
          (sc.game_mode == obs_ob.game_mode
          and sc.pass
          and not u.banned)),
      order_by: [asc: obs_ob.difficultyrating, desc: sc.pp],
      preload: [beatmapset: {obs, [beatmaps: {obs_ob, [scores: {sc, [user: u]}]}]}]

    beatmaps = for beatmap <- beatmap.beatmapset.beatmaps do
      scores = Enum.uniq_by(beatmap.scores, &(&1.user_id))
      %{beatmap | scores: scores}
    end

    beatmap = %{beatmap | beatmapset: %{beatmap.beatmapset | beatmaps: beatmaps}}

    render(conn, "beatmapset.json", beatmapset: beatmap.beatmapset)
  end
end

