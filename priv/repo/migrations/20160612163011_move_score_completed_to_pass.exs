defmodule Trucksu.Repo.Migrations.MoveScoreCompletedToPass do
  use Ecto.Migration

  def up do
    alter table(:scores) do
      remove :completed
      add :pass, :boolean
    end

    execute "UPDATE scores SET pass = true"

    alter table(:scores) do
      modify :pass, :boolean, null: false
    end
  end

  def down do
    alter table(:scores) do
      remove :pass
      add :completed, :integer
    end

    execute "UPDATE scores SET completed = 2"

    alter table(:scores) do
      modify :completed, :integer, null: false
    end
  end
end
