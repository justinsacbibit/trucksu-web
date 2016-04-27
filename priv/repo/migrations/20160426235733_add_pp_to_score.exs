defmodule Trucksu.Repo.Migrations.AddPpToScore do
  use Ecto.Migration

  def change do
    alter table(:scores) do
      add :pp, :float
    end
  end
end
