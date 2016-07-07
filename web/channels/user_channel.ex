defmodule Trucksu.UserChannel do
  use Trucksu.Web, :channel
  alias Trucksu.{User, UserStats}
  require Logger

  def join("users", _params, socket) do
    {:ok, socket}
  end

  # def handle_in("get:users", _, socket) do
  #   bancho_url = Application.get_env(:trucksu, :bancho_url)
  #   case HTTPoison.get(bancho_url <> "/api/v1/users") do
  #     {:ok, %HTTPoison.Response{body: user_actions}} ->
  #       user_actions = Poison.decode! user_actions
  #       users = for user_action <- user_actions do
  #         user = Repo.get! User, user_action["id"]
  #         rank = Repo.one(UserStats.get_rank(user_action["id"], 0))
  #         user_action
  #         |> Map.put("username", user.username)
  #         |> Map.put("rank", rank)
  #       end
  #       {:reply, {:ok, %{users: users}}, socket}
  #     {:error, error} ->
  #       Logger.error "Error getting online users from bancho: #{inspect error}"
  #       {:reply, {:error, %{}}, socket}
  #   end
  # end
end

