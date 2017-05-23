defmodule Trucksu.MatchChannel do
  use Trucksu.Web, :channel
  alias Trucksu.Env
  require Logger

  def join("matches", _params, socket) do
    case HTTPoison.get(Env.bancho_url() <> "/api/v1/matches") do
      {:ok, %HTTPoison.Response{body: matches}} ->
        matches = Poison.decode! matches
        {:ok, %{matches: matches}, socket}
      {:error, error} ->
        Logger.error "Error getting matches from bancho: #{inspect error}"
        {:error, %{}}
    end
  end
end

