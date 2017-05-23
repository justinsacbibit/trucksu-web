defmodule Trucksu.UserChannel do
  use Trucksu.Web, :channel
  alias Trucksu.{
    User,
    UserStats,
    Env,
  }
  require Logger

  def join("users", _params, socket) do
    {:ok, socket}
  end

  def join("users:" <> user_id, _params, socket) do
    case HTTPoison.get(Env.bancho_url() <> "/api/v1/users/#{user_id}") do
      {:ok, %HTTPoison.Response{body: user_action}} ->
        user_action = Poison.decode! user_action
        case user_action do
          %{"ok" => false} ->
            {:ok, %{user: nil}, socket}
          _ ->
            {:ok, %{user: fill_action(user_action)}, socket}
        end
      {:error, error} ->
        Logger.error "Error getting online user from bancho: #{inspect error}"
        {:error, %{}}
    end
  end

  def handle_in("get:users", _, socket) do
    case HTTPoison.get(Env.bancho_url() <> "/api/v1/users") do
      {:ok, %HTTPoison.Response{body: user_actions}} ->
        user_actions = Poison.decode! user_actions
        users = for user_action <- user_actions do
          fill_action(user_action)
        end
        {:reply, {:ok, %{users: users}}, socket}
      {:error, error} ->
        Logger.error "Error getting online users from bancho: #{inspect error}"
        {:reply, {:error, %{}}, socket}
    end
  end

  defp fill_action(user_action) do
    user_id = user_action["id"]
    user = Repo.get! User, user_id
    rank = Repo.one(UserStats.get_rank(user_id, 0))
    user_action
    |> Map.put("username", user.username)
    |> Map.put("rank", rank)
  end
end

