defmodule Trucksu.Repo.Migrations.CreateBeatmap do
  use Ecto.Migration

  def change do
    create table(:beatmaps) do
      add :filename, :string
      add :beatmapset_id, :integer
      add :file_md5, :string, null: false

      timestamps
    end

    create unique_index(:beatmaps, [:file_md5])
  end
end
