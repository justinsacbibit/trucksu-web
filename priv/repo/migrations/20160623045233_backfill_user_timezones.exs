defmodule Trucksu.Repo.Migrations.BackfillUserTimezones do
  use Ecto.Migration

  def change do
    execute "UPDATE users SET timezone = 0"

    alter table(:users) do
      modify :timezone, :integer, null: false
    end
  end
end
