defmodule Trucksu.Repo.Migrations.CreateUserStats do
  use Ecto.Migration

  def change do
    create table(:user_stats) do
      add :game_mode, :integer, null: false
      add :ranked_score, :bigint, null: false
      add :total_score, :bigint, null: false
      add :accuracy, :float, null: false
      add :playcount, :integer, null: false
      add :pp, :float, null: false
      add :replays_watched, :integer, null: false
      add :total_hits, :integer, null: false
      add :level, :integer, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps
    end

    create index(:user_stats, [:user_id])
    create unique_index(:user_stats, [:user_id, :game_mode])
  end
end
