defmodule Trucksu.Repo.Migrations.AddBannedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :banned, :boolean, null: false, default: false
    end
  end
end
