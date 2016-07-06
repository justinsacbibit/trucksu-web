defmodule Trucksu.ScoreView do
  use Trucksu.Web, :view

  def render("response.raw", %{data: data}), do: data

  def render("show.json", %{score: score}) do
    %{
      pp: round(score.pp),
      user: %{
        id: score.user.id,
        username: score.user.username,
      },
      osu_beatmap: %{
        id: score.osu_beatmap.id,
        version: score.osu_beatmap.version,
        beatmapset: %{
          artist: score.osu_beatmap.beatmapset.artist,
          title: score.osu_beatmap.beatmapset.title,
          creator: score.osu_beatmap.beatmapset.creator,
        }
      },
      mods: score.mods,
      rank: score.rank,
      accuracy: score.accuracy,
      max_combo: score.max_combo,
    }
  end
end

