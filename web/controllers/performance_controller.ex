defmodule Trucksu.PerformanceController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    Performance,
    OsuBeatmapFetcher,
  }

  plug :check_cookie

  defp check_cookie(conn, _) do
    cookie = conn.params["c"]
    expected_cookie = Application.get_env(:trucksu, :server_cookie)
    case cookie do
      ^expected_cookie -> conn
      _ -> stop_plug(conn, 403)
    end
  end

  def calculate(conn, %{"file_md5" => file_md5, "mods" => mods, "m" => game_mode}) do
    {mods, _} = Integer.parse(mods)
    {game_mode, _} = Integer.parse(game_mode)

    case Performance.calculate(file_md5, mods, game_mode) do
      {:ok, pp} ->
        {:ok, osu_beatmap} = OsuBeatmapFetcher.fetch(file_md5)
        data = %{
          "event_type" => "max-pp-calc",
          "pp" => "#{round pp}",
          "osu_beatmap" => osu_beatmap,
        }
        Logger.warn "Calculated #{round pp}pp for #{file_md5} #{osu_beatmap.artist} - #{osu_beatmap.title} (#{osu_beatmap.creator}) [#{osu_beatmap.version}]"
        json(conn, data)

      error ->
        Logger.error "Failed to calculate pp for file_md5=#{file_md5}"
        Logger.error inspect error

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

