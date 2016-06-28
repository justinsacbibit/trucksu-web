defmodule Trucksu.OsuDirectController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    OsuBeatmapset,
  }

  @ranking_type_global_selected_mods 2
  @ranking_type_global 1
  @ranking_type_country 4
  @ranking_type_friend 3

  @ranked_status_not_submitted -1
  @ranked_status_up_to_date 2
  @ranked_status_update_available 1

  @everything_is_ranked true

  # plug :authenticate when action in [:direct_index] # TODO: add :show_map?

  defp authenticate(conn, _) do
    username = conn.params["us"] || conn.params["u"]
    password_md5 = conn.params["ha"] || conn.params["h"]
    case Session.authenticate(username, password_md5, true) do
      {:error, reason} ->
        Logger.warn "#{username} attempted to get scores, but was unable to authenticate: #{reason}"
        stop_plug(conn, 403)
      {:ok, user} ->
        assign(conn, :user, user)
    end
  end

  def direct_index(conn, params) do
    beatmapsets = Repo.all from obs in OsuBeatmapset,
      select: obs

    data = Enum.reduce(beatmapsets, "", fn(beatmapset, data) ->
      data <> format_direct(beatmapset)
    end)

    data = "#{length beatmapsets}\n" <> data

    conn
    |> html(data)
  end

  defp format_direct(beatmapset) do
    has_video = 0 # 0 = no video, 1 = has video
    artist = String.replace(beatmapset.artist, "|", "I")
    title = String.replace(beatmapset.title, "|", "I")
    thread_id = beatmapset.id
    # missing difficulty names
    "#{beatmapset.id}.osz|#{artist}|#{title}|#{beatmapset.creator}|#{beatmapset.approved}|10.00000|1|#{beatmapset.id}|#{thread_id}|#{has_video}|0|0|0|diff\n"
    "#{beatmapset.id}.osz|#{artist}|#{title}|#{beatmapset.creator}|#{1}|10.00000|1|#{beatmapset.id}|#{thread_id}|#{has_video}|0|0||Diff@0|\n"
  end

  defp stop(conn, status_code) do
    conn
    |> put_status(status_code)
    |> html("")
  end

  defp stop_plug(conn, status_code) do
    stop(conn, status_code)
    |> halt
  end
end
