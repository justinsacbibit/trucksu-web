defmodule Trucksu.Repo.Migrations.AddScreenshotsTable do
  use Ecto.Migration

  def change do
    create table(:screenshots) do
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps
    end
  end
end
