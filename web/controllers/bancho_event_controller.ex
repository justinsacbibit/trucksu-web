defmodule Trucksu.BanchoEventController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.UserStats

  # TODO: Check server cookie

  defp put_rank(user) do
    Map.put(user, "rank", Repo.one(UserStats.get_rank(user["id"], 0)))
  end

  def create(conn, %{"type" => "user_online" = type, "user" => user}) do
    user = put_rank(user)
    Trucksu.Endpoint.broadcast! "users", type, %{user: user}

    conn
    |> json(%{"ok" => true})
  end

  def create(conn, %{"type" => "user_offline" = type, "user" => user}) do
    user = put_rank(user)
    Trucksu.Endpoint.broadcast! "users", type, %{user: user}

    conn
    |> json(%{"ok" => true})
  end

  def create(conn, %{"type" => "user_change_action" = type, "user" => user}) do
    user = put_rank(user)
    Trucksu.Endpoint.broadcast! "users", type, %{user: user}

    conn
    |> json(%{"ok" => true})
  end

  def create(conn, %{"type" => type}) do
    Logger.error "Got unknown type from bancho: #{inspect type}"

    conn
    |> json(%{"ok" => true})
  end
end

