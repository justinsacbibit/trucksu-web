defmodule Trucksu.MatchChannel do
  use Trucksu.Web, :channel
  require Logger

  @bancho_url Application.get_env(:trucksu, :bancho_url)

  def join("matches", _params, socket) do
    case HTTPoison.get(@bancho_url <> "/api/v1/matches") do
      {:ok, %HTTPoison.Response{body: matches}} ->
        matches = Poison.decode! matches
        {:ok, %{matches: matches}, socket}
      {:error, error} ->
        Logger.error "Error getting matches from bancho: #{inspect error}"
        {:error, %{}}
    end
  end
end

