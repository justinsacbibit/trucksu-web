defmodule Trucksu.Repo.Migrations.CreateFriendship do
  use Ecto.Migration

  def change do
    create table(:friendships) do
      add :requester_id, references(:users, on_delete: :nothing)
      add :receiver_id, references(:users, on_delete: :nothing)

      timestamps
    end
    create index(:friendships, [:requester_id])
    create index(:friendships, [:receiver_id])
    create unique_index(:friendships, [:requester_id, :receiver_id])

  end
end
