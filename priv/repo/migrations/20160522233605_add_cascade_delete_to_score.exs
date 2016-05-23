defmodule Trucksu.Repo.Migrations.AddCascadeDeleteToScore do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE scores DROP CONSTRAINT scores_file_md5_fkey"
    alter table(:scores) do
      modify :file_md5, references(:osu_beatmaps, column: :file_md5, type: :string, on_delete: :delete_all), null: false
    end
  end

  def down do
    execute "ALTER TABLE scores DROP CONSTRAINT scores_file_md5_fkey"
    alter table(:scores) do
      modify :file_md5, references(:osu_beatmaps, column: :file_md5, type: :string, on_delete: :nothing), null: false
    end
  end
end
