defmodule Trucksu.Repo.Migrations.AddUniqueIndexToOsuBeatmapFileMd5 do
  use Ecto.Migration

  def change do
    create unique_index(:osu_beatmaps, [:file_md5])
  end
end
