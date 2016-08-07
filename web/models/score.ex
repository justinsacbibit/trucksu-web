defmodule Trucksu.Score do
  use Trucksu.Web, :model

  @derive {Poison.Encoder, only: [
    :id,
    :score,
    :max_combo,
    :full_combo,
    :mods,
    :count_300,
    :count_100,
    :count_50,
    :katu_count,
    :geki_count,
    :miss_count,
    :time,
    :game_mode,
    :accuracy,
    :pass,
    :beatmap,
    :user,
    :pp,
    :has_replay,
    :rank,
  ]}

  schema "scores" do
    field :score, :integer
    field :max_combo, :integer
    field :full_combo, :integer
    field :mods, :integer
    field :count_300, :integer
    field :count_100, :integer
    field :count_50, :integer
    field :katu_count, :integer
    field :geki_count, :integer
    field :miss_count, :integer
    field :time, :string
    field :game_mode, :integer
    field :accuracy, :float
    field :pass, :boolean
    belongs_to :user, Trucksu.User
    field :pp, :float
    field :has_replay, :boolean
    field :rank, :string

    belongs_to :osu_beatmap, Trucksu.OsuBeatmap, foreign_key: :file_md5, references: :file_md5, type: :string

    timestamps
  end

  @required_fields ~w(score max_combo full_combo mods count_300 count_100 count_50 katu_count geki_count miss_count time game_mode accuracy pass user_id file_md5)
  @optional_fields ~w(pp has_replay rank)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
