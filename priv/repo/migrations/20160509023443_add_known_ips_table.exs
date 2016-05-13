defmodule Trucksu.Repo.Migrations.AddKnownIpsTable do
  use Ecto.Migration

  def change do
    create table(:known_ips) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :ip_address, :string, null: false

      timestamps
    end

    create unique_index(:known_ips, [:user_id, :ip_address])
  end
end
