defmodule Trucksu.Repo.Migrations.NullableUserTimezones do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :timezone, :integer, null: true
    end
  end
end
