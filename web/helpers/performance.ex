defmodule Trucksu.Performance do
  require Logger
  alias Trucksu.{OsuBeatmapFileFetcher, Repo}

  def calculate(score) do
    score = Repo.preload score, :beatmap
    with {:ok, osu_file_content} <- OsuBeatmapFileFetcher.fetch(score.beatmap.file_md5),
         do: calculate_with_osu_file_content(score, osu_file_content)
  end

  defp calculate_with_osu_file_content(score, osu_file_content) do
    form_data = [
      {"b", osu_file_content},
      {"Count300", score.count_300},
      {"Count100", score.count_100},
      {"Count50", score.count_50},
      {"CountMiss", score.miss_count},
      {"MaxCombo", score.max_combo},
      {"EnabledMods", score.mods},
      {"GameMode", score.game_mode},
    ]

    performance_url = Application.get_env(:trucksu, :performance_url)
    case HTTPoison.post performance_url, {:form, form_data} do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Poison.decode(body) do
          {:ok, %{"pp" => pp}} ->
            {:ok, pp}
          _ ->
            {:error, :json_error}
        end
      {:error, response} ->
        Logger.error "Failed to calculate pp for score: #{inspect score}"
        Logger.error "Response: #{inspect response}"
        {:error, :performance_error}
    end
  end
end

