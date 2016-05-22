defmodule Trucksu.Repo.Migrations.MoveApprovedFromBeatmapToBeatmapset do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2]

  def change do
    alter table(:osu_beatmapsets) do
      add :approved, :integer
    end

    execute "
    UPDATE osu_beatmapsets obs
    SET approved = ob.approved
    FROM osu_beatmaps ob
    WHERE ob.beatmapset_id = obs.id
    "
    alter table(:osu_beatmapsets) do
      modify :approved, :integer, null: false
    end

    alter table(:osu_beatmaps) do
      remove :approved
    end
  end
end
