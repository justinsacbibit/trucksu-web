defmodule Trucksu.RanksController do
  use Trucksu.Web, :controller
  alias Trucksu.{
    UserStats,
  }

  def index(conn, %{"m" => game_mode}) do
    get_stats(conn, game_mode)
  end
  def index(conn, _params) do
    get_stats(conn, 0)
  end

  defp get_stats(conn, game_mode) do
    query = if game_mode == 0 or game_mode == "0" do
      from us in UserStats,
        join: u in assoc(us, :user),
        where: u.banned == false
          and us.game_mode == ^game_mode,
        order_by: [desc: us.pp],
        preload: [user: u]
    else
      from us in UserStats,
        join: u in assoc(us, :user),
        where: u.banned == false
          and us.game_mode == ^game_mode,
        order_by: [desc: us.ranked_score],
        preload: [user: u]
    end

    stats = Repo.all query
    conn
    |> json(stats)
  end
end
