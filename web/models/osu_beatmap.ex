defmodule Trucksu.OsuBeatmap do
  use Trucksu.Web, :model
  alias Trucksu.Repo

  @derive {Poison.Encoder, only: [
    :id,
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
    field :filename, :string

    field :file_data, :binary, virtual: true

    has_many :scores, Trucksu.Score, foreign_key: :file_md5, references: :file_md5

    timestamps
  end

  @required_fields ~w(id beatmapset_id total_length hit_length version file_md5 diff_size diff_overall diff_approach diff_drain game_mode playcount passcount difficultyrating)
  @optional_fields ~w(max_combo filename)

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

  def set_filenames() do
    osu_beatmaps = Repo.all from ob in __MODULE__,
      join: obs in assoc(ob, :beatmapset),
      preload: [beatmapset: obs]

    for %__MODULE__{beatmapset: beatmapset} = osu_beatmap <- osu_beatmaps do
      changeset = Ecto.Changeset.change(osu_beatmap, filename: filename(osu_beatmap))
      Repo.update! changeset
    end
  end

  def filename(osu_beatmap) do
    osu_beatmap = Repo.preload osu_beatmap, :beatmapset
    beatmapset = osu_beatmap.beatmapset
    artist = strip_characters(beatmapset.artist)
    title = strip_characters(beatmapset.title)
    version = strip_characters(osu_beatmap.version)

    filename = "#{artist} - #{title} (#{beatmapset.creator}) [#{version}].osu"

    filename
  end

  defp strip_characters(str) do
    str
    |> String.replace(":", "")
    |> String.replace("*", "")
  end
end
