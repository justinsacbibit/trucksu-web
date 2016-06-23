defmodule Trucksu.Repo.Migrations.CreateOsuUserAccessPoint do
  use Ecto.Migration

  def change do
    create table(:osu_user_access_points) do
      add :osu_md5, :binary, null: false
      add :mac_md5, :binary, null: false
      add :unique_md5, :binary, null: false
      add :disk_md5, :binary
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps
    end
    create index(:osu_user_access_points, [:user_id])
    create unique_index(:osu_user_access_points, [
      :osu_md5,
      :mac_md5,
      :unique_md5,
      :disk_md5,
      :user_id,
    ], name: :osu_user_access_points_unique_index)

  end
end
