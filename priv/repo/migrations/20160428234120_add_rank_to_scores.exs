defmodule Trucksu.Repo.Migrations.AddRankToScores do
  use Ecto.Migration

  def change do
    alter table(:scores) do
      add :rank, :string, size: 2
    end
  end
end
