defmodule Trucksu.UserStats do
  use Trucksu.Web, :model
  alias Trucksu.{
    Score,
    User,
  }

  defimpl Poison.Encoder, for: Trucksu.UserStats do
    def encode(user_stats, _options) do
      %{
        pp: user_stats.pp,
        user: %{
          id: user_stats.user.id,
          username: user_stats.user.username,
        },
        game_mode: user_stats.game_mode,
        ranked_score: user_stats.ranked_score,
        total_score: user_stats.total_score,
        accuracy: user_stats.accuracy,
        playcount: user_stats.playcount,
        replays_watched: user_stats.replays_watched,
        total_hits: user_stats.total_hits,
        level: user_stats.level,
      } |> Poison.Encoder.encode([])
    end
  end

  schema "user_stats" do
    field :game_mode, :integer
    field :ranked_score, :integer
    field :total_score, :integer
    field :accuracy, :float
    field :playcount, :integer
    field :pp, :float
    field :replays_watched, :integer
    field :total_hits, :integer
    field :level, :integer
    belongs_to :user, User
    has_many :scores, through: [:user, :scores]
    field :rank, :integer, virtual: true

    timestamps
  end

  def create_for_user(user, mode) do
    defaults = %{
      user_id: user.id,
      game_mode: mode,
      ranked_score: 0,
      total_score: 0,
      accuracy: 1,
      playcount: 0,
      pp: 0,
      replays_watched: 0,
      total_hits: 0,
      level: 0,
    }
    changeset(%__MODULE__{}, defaults)
  end

  @required_fields ~w(game_mode ranked_score total_score accuracy playcount pp replays_watched total_hits level user_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_number(:accuracy, greater_than_or_equal_to: 0)
    |> validate_number(:game_mode, greater_than_or_equal_to: 0, less_than_or_equal_to: 3)
    |> validate_number(:level, greater_than_or_equal_to: 0)
    |> validate_number(:playcount, greater_than_or_equal_to: 0)
    |> validate_number(:pp, greater_than_or_equal_to: 0)
    |> validate_number(:ranked_score, greater_than_or_equal_to: 0)
    |> validate_number(:replays_watched, greater_than_or_equal_to: 0)
    |> validate_number(:total_hits, greater_than_or_equal_to: 0)
    |> validate_number(:total_score, greater_than_or_equal_to: 0)
  end
end
