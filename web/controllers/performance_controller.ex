defmodule Trucksu.PerformanceController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    Performance,
    OsuBeatmapFetcher,
  }

  @server_cookie Application.get_env(:trucksu, :server_cookie)

  plug :check_cookie

  defp check_cookie(conn, _) do
    cookie = conn.params["c"]
    server_cookie = @server_cookie
    case cookie do
      ^server_cookie -> conn
      _ -> stop_plug(conn, 403)
    end
  end

  def calculate(conn, %{"file_md5" => file_md5, "mods" => mods, "m" => game_mode, "acc" => acc}) do
    calculate_with_identifier(conn, file_md5, mods, game_mode, acc)
  end
  def calculate(conn, %{"file_md5" => file_md5, "mods" => mods, "m" => game_mode}) do
    calculate_with_identifier(conn, file_md5, mods, game_mode)
  end

  def calculate(conn, %{"b" => b, "mods" => mods, "m" => game_mode, "acc" => acc}) do
    {b, _} = Integer.parse(b)
    calculate_with_identifier(conn, b, mods, game_mode, acc)
  end
  def calculate(conn, %{"b" => b, "mods" => mods, "m" => game_mode}) do
    {b, _} = Integer.parse(b)
    calculate_with_identifier(conn, b, mods, game_mode)
  end

  defp calculate_with_identifier(conn, identifier, mods, game_mode, acc \\ -1) do
    {mods, _} = Integer.parse(mods)
    {game_mode, _} = Integer.parse(game_mode)

    case Performance.calculate(identifier, mods, game_mode, acc) do
      {:ok, result} ->
        {:ok, osu_beatmap} = OsuBeatmapFetcher.fetch(identifier)
        osu_beatmap = Repo.preload osu_beatmap, :beatmapset
        data = Map.merge(%{
          "osu_beatmap" => osu_beatmap,
        }, result)
        Logger.info "Calculated pp: #{inspect data}"
        json(conn, data)

      error ->
        Logger.error "Failed to calculate pp for identifier=#{identifier}: #{inspect error}"

        conn
        |> put_status(500)
        |> json(%{errors: %{detail: "Server internal error"}})
    end
  end

  defp stop(conn, status_code) do
    conn
    |> put_status(status_code)
    |> json(%{})
  end

  defp stop_plug(conn, status_code) do
    stop(conn, status_code)
    |> halt
  end
end

