defmodule Trucksu.Repo.Migrations.AddCountryToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :country, :string, size: 2
    end
  end
end
