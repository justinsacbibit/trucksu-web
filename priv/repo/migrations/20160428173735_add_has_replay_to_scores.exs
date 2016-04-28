defmodule Trucksu.Repo.Migrations.AddHasReplayToScores do
  use Ecto.Migration
  require Logger
  alias Trucksu.{Repo, Score}

  def up do
    # Note: For each replay already in S3, this should be updated to true
    alter table(:scores) do
      add :has_replay, :boolean, default: false
    end

    # Execute the above table alter
    flush()

    :hackney.start
    ExAws.start(nil, nil)
    scores_with_replays =
    ExAws.S3.list_objects!(System.get_env("REPLAY_FILE_BUCKET"))
    |> Map.get(:body)
    |> Map.get(:contents)
    |> Enum.map(&(Map.get(&1, :key)))

    Repo.start_link
    Enum.each(scores_with_replays, fn score_id ->
      case Repo.get Score, score_id do
        nil ->
          Logger.error "Found a replay for score #{score_id}, but that score doesn't exist"
        score ->
          changeset = Ecto.Changeset.change score, %{has_replay: true}
          Repo.update! changeset
      end
    end)
  end

  def down do
    alter table(:scores) do
      remove :has_replay
    end
  end
end
