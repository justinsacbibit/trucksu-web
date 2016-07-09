defmodule Trucksu.BanchoEventController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.UserStats

  # TODO: Check server cookie

  defp put_rank(user) do
    Map.put(user, "rank", Repo.one(UserStats.get_rank(user["id"], 0)))
  end

  defp broadcast_user(user, event_type) do
    user = put_rank(user)
    Trucksu.Endpoint.broadcast! "users", event_type, %{user: user}
    Trucksu.Endpoint.broadcast! "users:#{user["id"]}", event_type, %{user: user}
  end

  defp broadcast_match(match, event_type) do
    Trucksu.Endpoint.broadcast! "matches", event_type, %{match: match}
  end

  def create(conn, %{"type" => "user_online" = type, "user" => user}) do
    broadcast_user(user, type)

    conn
    |> json(%{"ok" => true})
  end

  def create(conn, %{"type" => "user_offline" = type, "user" => user}) do
    broadcast_user(user, type)

    conn
    |> json(%{"ok" => true})
  end

  def create(conn, %{"type" => "user_change_action" = type, "user" => user}) do
    broadcast_user(user, type)

    conn
    |> json(%{"ok" => true})
  end

  def create(conn, %{"type" => "match_create" = type, "match" => match}) do
    broadcast_match(match, type)

    conn
    |> json(%{"ok" => true})
  end

  def create(conn, %{"type" => "match_update" = type, "match" => match}) do
    broadcast_match(match, type)

    conn
    |> json(%{"ok" => true})
  end

  def create(conn, %{"type" => "match_destroy" = type, "match" => match}) do
    broadcast_match(match, type)

    conn
    |> json(%{"ok" => true})
  end

  def create(conn, %{"type" => type}) do
    Logger.error "Got unknown type from bancho: #{inspect type}"

    conn
    |> json(%{"ok" => true})
  end
end

