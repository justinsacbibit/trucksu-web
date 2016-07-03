defmodule Trucksu.Repo.Migrations.CreateUserGroup do
  use Ecto.Migration

  def change do
    create table(:user_groups) do
      add :user_id, references(:users, on_delete: :nothing)
      add :group_id, references(:groups, on_delete: :nothing)

      timestamps
    end
    create index(:user_groups, [:user_id])
    create index(:user_groups, [:group_id])
    create unique_index(:user_groups, [:user_id, :group_id])

  end
end
