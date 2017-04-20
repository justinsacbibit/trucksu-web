defmodule Trucksu.Repo.Migrations.CreateOsuBeatmapset do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2]
  alias Trucksu.{Repo, OsuBeatmap, OsuBeatmapset, Score, NewOsuBeatmap}

  @md5_hash_length 32

  def change do
    create table(:osu_beatmapsets, primary_key: false) do
      add :id, :integer, primary_key: true

      add :approved_date, :datetime
      add :last_update, :datetime, null: false
      add :artist, :string, null: false
      add :title, :string, null: false
      add :creator, :string, null: false
      add :bpm, :float, null: false
      add :source, :string, null: false
      add :tags, :string, size: 1000, null: false
      add :genre_id, :integer
      add :language_id, :integer
      add :favorite_count, :integer, null: false

      timestamps
    end

    # Already run in prod
    # # Execute the above table alter
    # flush()

    # beatmapset_data = Repo.all from ob in OsuBeatmap,
    #   distinct: ob.beatmapset_id

    # for beatmap <- beatmapset_data do
    #   changeset = OsuBeatmapset.changeset(%OsuBeatmapset{}, %{
    #     id: beatmap.beatmapset_id,
    #     approved_date: beatmap.approved_date,
    #     last_update: beatmap.last_update,
    #     artist: beatmap.artist,
    #     title: beatmap.title,
    #     creator: beatmap.creator,
    #     bpm: beatmap.bpm,
    #     source: beatmap.source,
    #     tags: beatmap.tags,
    #     genre_id: beatmap.genre_id,
    #     language_id: beatmap.language_id,
    #     favorite_count: beatmap.favourite_count,
    #   })

    #   Repo.insert! changeset
    # end

    alter table(:osu_beatmaps) do
      modify :beatmapset_id, references(:osu_beatmapsets), null: false
      modify :approved, :integer, null: false
      modify :total_length, :integer, null: false
      modify :hit_length, :integer, null: false
      modify :version, :string, null: false
      modify :file_md5, :string, null: false, size: @md5_hash_length
      modify :diff_size, :float, null: false
      modify :diff_overall, :float, null: false
      modify :diff_approach, :float, null: false
      modify :diff_drain, :float, null: false
      modify :game_mode, :integer, null: false
      modify :max_combo, :integer
      modify :playcount, :integer, null: false
      modify :passcount, :integer, null: false
      modify :difficultyrating, :float, null: false

      remove :approved_date
      remove :last_update
      remove :artist
      remove :title
      remove :creator
      remove :bpm
      remove :source
      remove :tags
      remove :genre_id
      remove :language_id
      remove :favourite_count
    end

    create index(:osu_beatmaps, [:beatmapset_id])

    alter table(:scores) do
      add :file_md5, :string, size: @md5_hash_length
    end

    # Already run in prod
    # flush()

    # scores = Repo.all from sc in Score,
    #   join: b in assoc(sc, :beatmap),
    #   left_join: ob in NewOsuBeatmap,
    #     on: b.file_md5 == ob.file_md5,
    #   preload: [beatmap: {b, [osu_beatmap: ob]}]

    # for score <- scores do
    #   if is_nil(score.beatmap.osu_beatmap) do
    #     Repo.delete! score
    #   else
    #     changeset = Score.changeset(score, %{file_md5: score.beatmap.file_md5})
    #     Repo.update! changeset
    #   end
    # end

    alter table(:scores) do
      modify :file_md5, references(:osu_beatmaps, column: :file_md5, type: :string), null: false
      remove :beatmap_id
    end

    create index(:scores, [:file_md5])

    drop table(:beatmaps)
  end
end
