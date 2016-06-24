defmodule Trucksu.Repo.Migrations.NullableUserTimezones do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :timezone, :integer, null: true
    end
  end

  def down do
    alter table(:users) do
      modify :timezone, :integer, null: false
    end
  end
end
