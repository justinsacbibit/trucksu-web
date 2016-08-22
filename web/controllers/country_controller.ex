defmodule Trucksu.CountryController do
  use Trucksu.Web, :controller
  alias Trucksu.{
    UserStats,
    Countries,
  }

  def index(conn, _params) do
    users = Repo.all from us in UserStats,
      join: u in assoc(us, :user),
      where: u.banned == false
        and us.game_mode == 0,
      preload: [user: u]

    users = users
    |> Enum.group_by(fn(user_stats) -> user_stats.user.country end)
    |> Enum.filter(fn({country, _}) -> not is_nil(country) end)
    |> Enum.map(fn({country, user_stats}) ->
      acc = %{
        ranked_score: 0,
        total_score: 0,
        accuracy: 0,
        playcount: 0,
        pp: 0,
        total_hits: 0,
      }

      # Combine the accumulator for the country with the stats for the current user
      combine = fn(acc, user_stats) ->
        # Reduce over each stat (playcount, pp, etc.)
        Enum.reduce(acc, %{}, fn({key, value}, acc) ->
          Map.put(acc, key, value + Map.get(user_stats, key))
        end)
      end

      # Reduce over each user in the country
      stats_for_country = Enum.reduce(user_stats, acc, fn(user_stats, acc) ->
        combine.(acc, user_stats)
      end)

      # Update accuracy to be the mean
      mean_accuracy = stats_for_country[:accuracy] / length(user_stats)
      stats_for_country = %{stats_for_country | accuracy: mean_accuracy}

      %{
        country: %{
          code: country,
          name: Countries.country_name(country),
        },
        stats: stats_for_country,
      }
    end)
    |> Enum.sort_by(fn(res) -> res[:stats][:pp] end, &>/2)
    conn
    |> json(users)
  end
end
