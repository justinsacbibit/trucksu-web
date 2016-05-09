defmodule Trucksu.Repo.Migrations.ChangeDiscordIdToString do
  use Ecto.Migration

  def change do
    alter table(:discord_admins) do
      modify :discord_id, :string, null: false
    end
  end
end
