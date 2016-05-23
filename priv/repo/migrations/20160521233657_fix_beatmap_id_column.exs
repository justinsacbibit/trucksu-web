defmodule Trucksu.Repo.Migrations.FixBeatmapIdColumn do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2]
  alias Trucksu.{Repo, OsuBeatmap}

  def change do
    # Fix beatmap_id collisions. Keep the one with the latest inserted_at
    execute "
    DELETE FROM osu_beatmaps obs
    USING osu_beatmaps obs2
    WHERE obs.beatmap_id = obs2.beatmap_id
      AND obs.id != obs2.id
      AND obs.inserted_at < obs2.inserted_at
    "

    # We want to copy osu_beatmap.beatmap_id to osu_beatmap.id, but the id
    # might be taken.
    execute "
    UPDATE osu_beatmaps ob
    SET id = ob.beatmap_id
    FROM osu_beatmaps ob2
    WHERE ob.id <> ob.beatmap_id
      AND ob.id = ob2.beatmap_id
    "

    execute "
    DELETE FROM osu_beatmaps ob
    USING osu_beatmaps ob2
    WHERE ob.id = ob2.beatmap_id
    "

    execute "
    UPDATE osu_beatmaps
    SET id = beatmap_id
    WHERE id <> beatmap_id
    "

    alter table(:osu_beatmaps) do
      remove :beatmap_id
    end
  end
end
