defmodule Trucksu.Repo.Migrations.CreateOsuBeatmap do
  use Ecto.Migration

  def change do
    create table(:osu_beatmaps) do
      add :beatmapset_id, :integer
      add :beatmap_id, :integer
      add :approved, :integer
      add :total_length, :integer
      add :hit_length, :integer
      add :version, :string
      add :file_md5, :string
      add :diff_size, :float
      add :diff_overall, :float
      add :diff_approach, :float
      add :diff_drain, :float
      add :game_mode, :integer
      add :approved_date, :datetime
      add :last_update, :datetime
      add :artist, :string
      add :title, :string
      add :creator, :string
      add :bpm, :float
      add :source, :string
      add :tags, :string, size: 1000
      add :genre_id, :integer
      add :language_id, :integer
      add :favourite_count, :integer
      add :playcount, :integer
      add :passcount, :integer
      add :max_combo, :integer
      add :difficultyrating, :float

      timestamps
    end

  end
end
