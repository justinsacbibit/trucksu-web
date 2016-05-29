defmodule Trucksu.OsuBeatmapPageController do
  use Trucksu.Web, :controller

  def show_beatmap(conn, %{"beatmap_id" => beatmap_id}) do
    redirect conn, external: "http://new.ppy.sh/b/#{beatmap_id}"
  end

  def show_beatmapset(conn, %{"beatmapset_id" => beatmapset_id}) do
    redirect conn, external: "http://new.ppy.sh/s/#{beatmapset_id}"
  end
end

