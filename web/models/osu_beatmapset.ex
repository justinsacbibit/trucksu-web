defmodule Trucksu.OsuBeatmapset do
  use Trucksu.Web, :model

  schema "osu_beatmapsets" do
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
    field :favorite_count, :integer

    timestamps
  end

  @required_fields ~w(id last_update artist title creator bpm source tags favorite_count)
  @optional_fields ~w(approved_date genre_id language_id)

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
