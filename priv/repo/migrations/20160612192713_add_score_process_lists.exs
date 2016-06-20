defmodule Trucksu.Repo.Migrations.AddScoreProcessLists do
  use Ecto.Migration

  def change do
    create table(:score_process_lists) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :score_id, references(:scores, on_delete: :nothing), null: false
      add :process_list, :string, size: 9000
      add :version, :string

      timestamps
    end
  end
end
