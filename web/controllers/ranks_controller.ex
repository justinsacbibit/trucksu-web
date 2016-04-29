defmodule Trucksu.RanksController do
  use Trucksu.Web, :controller
  alias Trucksu.UserStats

  def index(conn, _params) do
    # TODO: Check params cookie
    stats = Repo.all from us in UserStats,
      join: u in assoc(us, :user),
      where: us.game_mode == 0,
      order_by: [desc: us.pp],
      preload: [user: u]
    conn
    |> json(stats)
  end
end

