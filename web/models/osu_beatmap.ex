defmodule Trucksu.OsuBeatmap do
  use Trucksu.Web, :model

  schema "osu_beatmaps" do
    field :beatmapset_id, :integer
    field :beatmap_id, :integer
    field :approved, :integer
    field :total_length, :integer
    field :hit_length, :integer
    field :version, :string
    field :file_md5, :string
    field :diff_size, :float
    field :diff_overall, :float
    field :diff_approach, :float
    field :diff_drain, :float
    field :game_mode, :integer
    field :approved_date, Ecto.DateTime
    field :last_update, Ecto.DateTime
    field :artist, :string
    field :title, :string
    field :creator, :string
    field :bpm, :float
    field :source, :string
    field :tags, :string
    field :genre_id, :integer
    field :language_id, :integer
    field :favourite_count, :integer
    field :playcount, :integer
    field :passcount, :integer
    field :max_combo, :integer
    field :difficultyrating, :float

    field :file_data, :binary, virtual: true

    timestamps
  end

  @required_fields ~w(beatmapset_id beatmap_id approved total_length hit_length version file_md5 diff_size diff_overall diff_approach diff_drain game_mode last_update artist title creator bpm source tags genre_id language_id favourite_count playcount passcount max_combo difficultyrating)
  @optional_fields ~w(approved_date)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
