defmodule Trucksu.Repo.Migrations.AddInternalUserReports do
  use Ecto.Migration

  def change do
    create table(:internal_user_reports) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :process_list, :string, size: 9000
      add :version, :string

      timestamps
    end
  end
end
