defmodule Trucksu.Beatmap do
  use Trucksu.Web, :model
  alias Trucksu.{
    OsuBeatmap,
    Score,
  }

  schema "beatmaps" do
    field :filename, :string
    field :beatmapset_id, :integer
    field :file_md5, :string
    has_many :scores, Score
    has_one :osu_beatmap, OsuBeatmap, foreign_key: :file_md5, references: :file_md5

    timestamps
  end

  @required_fields ~w(file_md5)
  @optional_fields ~w(filename beatmapset_id)

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
end
