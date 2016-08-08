defmodule Trucksu.UserView do
  use Trucksu.Web, :view
  alias Trucksu.{
    GraphView,
  }

  def render("friends.json", %{friends: friends}) do
    render_many(friends, __MODULE__, "friend.json", as: :friend)
  end

  def render("friend.json", %{friend: friend}) do
    friend
  end

  def render("show.json", %{user: user}) do
    %{
      id: user.id,
      country: user.country,
      username: user.username,
    }
  end

  def render("user_detail.json", %{
    user: user,
    friendship: friendship,
    graphs: graphs
  }) do
    data = %{
      id: user.id,
      country: user.country,
      country_name: country_name(user.country),
      username: user.username,
      groups: render_many(user.groups, Trucksu.GroupView, "show.json"),
      inserted_at: user.inserted_at,
      stats: for user_stats <- user.stats do
        %{
          graphs: graphs[user_stats.game_mode]
          |> Enum.map(fn({key, val}) ->
            {key, %{
              points: render(GraphView, "show.json", points: val),
            }}
          end)
          |> Enum.into(%{}),
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

    data = if not is_nil(friendship) do
      Map.put(data, :friendship, friendship)
    else
      data
    end

    data
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
      unix_time: parse_osu_time(score.time),
      game_mode: score.game_mode,
      accuracy: score.accuracy,
      pass: score.pass,
      beatmap: score.osu_beatmap,
      pp: score.pp,
      has_replay: score.has_replay,
      rank: score.rank,
    }
  end

  defp country_name(country_code) do
    case Countries.filter_by(:alpha2, country_code) do
      [%{name: name}] ->
        to_string(name)
      _ ->
        nil
    end
  end

  defp parse_osu_time(time) do
    case Timex.parse(time, "{YY}{0M}{0D}{h24}{m}{s}") do
      {:ok, datetime} ->
        case Timex.format(datetime, "{s-epoch}") do
          {:ok, unix_time} ->
            case Integer.parse(unix_time) do
              {int, _} -> int
              _ -> nil
            end
          _ -> nil
        end
      _ -> nil
    end
  end
end

