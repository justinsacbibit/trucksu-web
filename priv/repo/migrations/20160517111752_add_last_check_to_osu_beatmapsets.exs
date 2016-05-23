defmodule Trucksu.Repo.Migrations.AddLastCheckToOsuBeatmapsets do
  use Ecto.Migration

  def change do
    alter table(:osu_beatmapsets) do
      add :last_check, :datetime, default: "01-01-1970"
    end
  end
end
