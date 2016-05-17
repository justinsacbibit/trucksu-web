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
    :completed,
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
    field :completed, :integer
    belongs_to :beatmap, Trucksu.Beatmap
    belongs_to :user, Trucksu.User
    field :pp, :float
    field :has_replay, :boolean
    field :rank, :string

    field :file_md5, :string # TODO: Change to reference OsuBeatmap

    timestamps
  end

  @required_fields ~w(score max_combo full_combo mods count_300 count_100 count_50 katu_count geki_count miss_count time game_mode accuracy completed user_id beatmap_id file_md5)
  @optional_fields ~w(pp has_replay rank)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def completed(query \\ __MODULE__) do
    from s in query,
      where: s.completed == 2 or s.completed == 3
  end
end
