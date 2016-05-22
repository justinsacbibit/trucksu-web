defmodule Trucksu.OsuBeatmap do
  use Trucksu.Web, :model

  @derive {Poison.Encoder, only: [
    :version,
    :diff_size,
    :diff_overall,
    :diff_approach,
    :diff_drain,
    :game_mode,
    :difficultyrating,
    :beatmapset,
  ]}

  schema "osu_beatmaps" do
    belongs_to :beatmapset, Trucksu.OsuBeatmapset
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

    has_many :scores, Score, foreign_key: :file_md5, references: :file_md5

    timestamps
  end

  @required_fields ~w(id beatmapset_id total_length hit_length version file_md5 diff_size diff_overall diff_approach diff_drain game_mode playcount passcount difficultyrating)
  @optional_fields ~w(max_combo)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:file_md5)
  end

  def changeset_from_api(model, params) do
    params = params
    |> Map.put("game_mode", Map.get(params, "mode"))
    |> Map.put("id", Map.get(params, "beatmap_id"))

    changeset(model, params)
  end
end
