defmodule Trucksu.OsuBeatmapset do
  use Trucksu.Web, :model
  use Timex

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

    field :last_check, Ecto.DateTime

    timestamps
  end

  @required_fields ~w(id last_update artist title creator bpm source tags favorite_count last_check)
  @optional_fields ~w(approved_date genre_id language_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> change(last_check: Time.now) # TODO: figure out last_check
  end

  def changeset_from_api(model, params) do
    params = params
    |> Map.put("id", Map.get(params, "beatmapset_id"))
    |> Map.put("favorite_count", Map.get(params, "favourite_count"))
    |> Map.put("last_check", Time.now)

    changeset(model, params)
  end
end
