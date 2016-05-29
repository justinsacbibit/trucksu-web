defmodule Trucksu.ReplayController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    Session,

    Repo,
    Score,
  }

  plug :authenticate
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
      where: s.id == ^score_id and s.game_mode == ^game_mode
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

