defmodule Trucksu.ReplayController do
  use Trucksu.Web, :controller

  def show(conn, %{"c" => score_id} = params) do
    # TODO: Check auth

    bucket = Application.get_env(:trucksu, :replay_file_bucket)
    case ExAws.S3.get_object(bucket, score_id) do
      {:error, {:http_error, 404, _}} ->
        raise :err_no_replay
      {:ok, %{body: replay_file_content}} ->
        # TODO: Update replays_watched count
        render conn, "response.raw", data: replay_file_content
    end
  end
end

