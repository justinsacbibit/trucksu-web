defmodule Trucksu.OsuBeatmapView do
  use Trucksu.Web, :view

  def render("beatmap.json", %{beatmap: %{beatmapset: beatmapset} = beatmap}) do
    IO.inspect beatmap

    %{
      id: beatmap.id,
      version: beatmap.version,
      diff_size: beatmap.diff_size,
      diff_overall: beatmap.diff_overall,
      diff_approach: beatmap.diff_approach,
      diff_drain: beatmap.diff_drain,
      game_mode: beatmap.game_mode,
      difficultyrating: beatmap.difficultyrating,
      total_length: beatmap.total_length,
      hit_length: beatmap.hit_length,
      max_combo: beatmap.max_combo,

      beatmapset: %{
        id: beatmapset.id,
        approved: beatmapset.approved,
        approved_date: beatmapset.approved_date,
        last_update: beatmapset.last_update,
        artist: beatmapset.artist,
        title: beatmapset.title,
        creator: beatmapset.creator,
        bpm: beatmapset.bpm,
        source: beatmapset.source,
        tags: beatmapset.tags,
        genre_id: beatmapset.genre_id,
        language_id: beatmapset.language_id,
        beatmaps: for beatmap <- beatmapset.beatmaps do
          %{
            id: beatmap.id,
            version: beatmap.version,
          }
        end,
      },
      scores: for score <- beatmap.scores do
        %{
          id: score.id,
          score: score.score,
          max_combo: score.max_combo,
          full_combo: score.full_combo,
          mods: score.mods,
          count_300: score.count_300,
          count_100: score.count_100,
          count_50: score.count_50,
          katu_count: score.katu_count,
          geki_count: score.geki_count,
          miss_count: score.miss_count,
          # time: score.time,
          game_mode: score.game_mode,
          accuracy: score.accuracy,
          pass: score.pass,
          user: %{
            username: score.user.username,
          },
          pp: score.pp,
          rank: score.rank,

          inserted_at: score.inserted_at,
        }
      end,
    }
  end
end

