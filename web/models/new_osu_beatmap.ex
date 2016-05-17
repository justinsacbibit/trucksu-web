defmodule Trucksu.NewOsuBeatmap do
  use Trucksu.Web, :model
  alias Trucksu.OsuBeatmapset

  @derive {Poison.Encoder, only: [
    :beatmap_id,
    :version,
    :diff_size,
    :diff_overall,
    :diff_approach,
    :diff_drain,
    :game_mode,
    :approved_date,
    :last_update,
    :artist,
    :title,
    :creator,
    :bpm,
    :difficultyrating,
  ]}

  schema "osu_beatmaps" do
    belongs_to :beatmapset, OsuBeatmapset
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
    field :playcount, :integer
    field :passcount, :integer
    field :max_combo, :integer
    field :difficultyrating, :float

    field :file_data, :binary, virtual: true

    timestamps
  end

  @required_fields ~w(id beatmapset_id approved total_length hit_length version file_md5 diff_size diff_overall diff_approach diff_drain game_mode favourite_count playcount passcount difficultyrating)
  @optional_fields ~w(max_combo)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def changeset_from_api(model, params) do
    params = Map.put(params, "game_mode", Map.get(params, "mode"))

    changeset(model, params)
  end
end
