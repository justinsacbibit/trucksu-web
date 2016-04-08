defmodule Trucksu.Repo.Migrations.CreateScore do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :score, :integer, null: false
      add :max_combo, :integer, null: false
      add :full_combo, :integer, null: false
      add :mods, :integer, null: false
      add :count_300, :integer, null: false
      add :count_100, :integer, null: false
      add :count_50, :integer, null: false
      add :katu_count, :integer, null: false
      add :geki_count, :integer, null: false
      add :miss_count, :integer, null: false
      add :time, :string, null: false
      add :game_mode, :integer, null: false
      add :accuracy, :float, null: false
      add :completed, :integer, null: false
      add :beatmap_id, references(:beatmaps, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps
    end

    create index(:scores, [:beatmap_id])
    create index(:scores, [:user_id])
  end
end
