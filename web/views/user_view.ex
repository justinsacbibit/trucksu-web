defmodule Trucksu.UserView do
  use Trucksu.Web, :view

  def render("user_detail.json", user) do

    %{
      id: user.id,
      country: user.country,
      username: user.username,
      stats: for user_stats <- user.stats do
        %{
          pp: user_stats.pp,
          rank: user_stats.rank,
          game_mode: user_stats.game_mode,
          ranked_score: user_stats.ranked_score,
          total_score: user_stats.total_score,
          accuracy: user_stats.accuracy,
          playcount: user_stats.playcount,
          replays_watched: user_stats.replays_watched,
          total_hits: user_stats.total_hits,
          level: user_stats.level,
          scores: render_many(user_stats.scores, __MODULE__, "score.json", as: :score),
          first_place_scores: render_many(user_stats.first_place_scores, __MODULE__, "score.json", as: :score),
        }
      end,
    }
  end

  def render("score.json", %{score: score}) do
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
      time: score.time,
      game_mode: score.game_mode,
      accuracy: score.accuracy,
      completed: score.completed,
      beatmap: score.beatmap.osu_beatmap,
      pp: score.pp,
      has_replay: score.has_replay,
      rank: score.rank,
    }
  end
end

