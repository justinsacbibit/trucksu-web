defmodule Trucksu.Repo.Migrations.CreateDiscordAdmin do
  use Ecto.Migration

  def change do
    create table(:discord_admins) do
      add :discord_id, :integer, null: false

      timestamps
    end
    create unique_index(:discord_admins, [:discord_id])

  end
end
