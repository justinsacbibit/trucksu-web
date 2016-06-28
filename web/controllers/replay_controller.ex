defmodule Trucksu.ReplayController do
  use Trucksu.Web, :controller
  use Bitwise
  require Logger
  alias Trucksu.{
    Session,

    Repo,
    Score,
  }
  alias Trucksu.Constants.Mods

  plug :authenticate when action in [:show]
  plug Guardian.Plug.EnsureAuthenticated, [handler: Trucksu.SessionController] when action in [:show_full]
  plug :find_score
  plug :find_replay

  defp authenticate(%Plug.Conn{params: %{"u" => username, "h" => password_md5}} = conn, _) do
    case Session.authenticate(username, password_md5, true) do
      {:error, reason} ->
        Logger.warn "#{username} attempted to get a replay, but was unable to authenticate: #{reason}"
        stop_plug(conn, 403)
      {:ok, user} ->
        assign(conn, :user, user)
    end
  end
  defp authenticate(conn, _) do
    stop_plug(conn, 400)
  end

  defp find_score(%Plug.Conn{params: %{"c" => score_id, "m" => game_mode}} = conn, _) do
    query = from s in Score,
      join: u in assoc(s, :user),
      where: s.id == ^score_id and s.game_mode == ^game_mode,
      preload: [user: u]

    case Repo.one query do
      nil ->
        stop_plug(conn, 404)
      score ->
        assign(conn, :score, score)
    end
  end
  defp find_score(conn, _) do
    stop_plug(conn, 400)
  end

  defp find_replay(conn, _) do
    score = conn.assigns[:score]

    bucket = Application.get_env(:trucksu, :replay_file_bucket)
    case ExAws.S3.get_object(bucket, "#{score.id}") do
      {:error, {:http_error, 404, _}} ->

        changeset = Ecto.Changeset.change score, %{has_replay: false}
        Repo.update! changeset

        stop_plug(conn, 404)

      {:ok, %{body: replay_file_content}} ->

        changeset = Ecto.Changeset.change score, %{has_replay: true}
        score = Repo.update! changeset

        conn
        |> assign(:replay_file_content, replay_file_content)
        |> assign(:score, score)
    end
  end

  def show(conn, _params) do
    # If the watcher is not the one who set the score, increment replays_watched
    score = conn.assigns[:score]
    if conn.assigns[:user].id != score.user_id do
      sql = "
      UPDATE user_stats
      SET replays_watched=replays_watched+1
      WHERE user_id=$1 AND game_mode=$2
      "
      Ecto.Adapters.SQL.query! Repo, sql, [score.user_id, score.game_mode]
    end

    replay_file_content = conn.assigns[:replay_file_content]
    html conn, replay_file_content
  end

  def show_full(conn, _params) do
    score = conn.assigns[:score]

    replay_file_content = conn.assigns[:replay_file_content]

    full_combo = case score.full_combo do
      1 -> "True"
      _ -> "False"
    end

    total_notes = score.count_300 + count_100 + count_50 + miss_count
    percent_300 = score.count_300 / total_notes
    percent_50 = score.count_50 / total_notes

    hidden =
      (score.mods &&& Mods.hidden ||| score.mods &&& Mods.flashlight) != 0

    rank = cond do
      percent_300 == 1 ->
        if hidden do
          "XH"
        else
          "X"
        end

      percent_300 > 0.9 and percent_50 <= 0.01 and score.count_miss == 0 ->
        if hidden do
          "SH"
        else
          "S"
        end

      (percent_300 > 0.8 and score.count_miss == 0) or percent_300 > 0.9 ->
        "A"

      (percent_300 > 0.7 and score.count_miss == 0) or percent_300 > 0.8 ->
        "B"

      percent_300 > 0.6 ->
        "C"

      true ->
        "D"
    end

    # TODO: Verify that this is right
    magic_string = "#{score.count_100}p#{score.count_300}o#{score.count_50}o#{score.geki_count}t#{score.katu_count}a#{score.miss_count}r#{score.file_md5}e#{score.max_combo}y#{full_combo}o#{score.user.username}u#{score.score}#{rank}#{score.mods}" |> Trucksu.Hash.md5

    html conn, replay_file_content
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

