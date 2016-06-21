defmodule Trucksu.OsuBeatmapPageController do
  use Trucksu.Web, :controller

  def show_beatmap(conn, %{"beatmap_id" => beatmap_id}) do
    website_url = Application.get_env(:trucksu, :website_url)
    redirect conn, external: "#{website_url}/beatmaps/#{beatmap_id}"
  end

  def show_beatmapset(conn, %{"beatmapset_id" => beatmapset_id}) do
    redirect conn, external: "http://new.ppy.sh/s/#{beatmapset_id}"
  end
end

