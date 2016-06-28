defmodule Trucksu.Repo.Migrations.RemoveScoreProcessListFkey do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE score_process_lists DROP CONSTRAINT score_process_lists_score_id_fkey"
  end

  def down do
    alter table(:score_process_lists) do
      modify :score_id, references(:scores), null: false
    end
  end
end
