defmodule Trucksu.Repo.Migrations.AddFilenameToOsuBeatmaps do
  use Ecto.Migration
  alias Trucksu.{
    OsuBeatmap,
  }


  def up do

    {:ok, _} = Application.ensure_all_started(:tzdata)

    alter table(:osu_beatmaps) do
      add :filename, :string
    end

    flush()

    OsuBeatmap.set_filenames()

    alter table(:osu_beatmaps) do
      modify :filename, :string, null: false
    end
  end

  def down do
    alter table(:osu_beatmaps) do
      remove :filename
    end
  end
end
