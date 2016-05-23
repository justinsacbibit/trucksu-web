defmodule Trucksu.Repo.Migrations.AddUnsubmittedToOsuBeatmapsets do
  use Ecto.Migration

  def change do
    alter table(:osu_beatmapsets) do
      add :unsubmitted, :boolean, default: false, null: false
    end
  end
end
