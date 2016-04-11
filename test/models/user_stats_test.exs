defmodule Trucksu.UserStatsTest do
  use Trucksu.ModelCase

  alias Trucksu.UserStats

  @valid_attrs %{
    accuracy: 94.5,
    game_mode: 0,
    level: 42,
    playcount: 42,
    pp: 120.5,
    ranked_score: 42,
    replays_watched: 42,
    total_hits: 42,
    total_score: 42,
    user_id: 3,
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = UserStats.changeset(%UserStats{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = UserStats.changeset(%UserStats{}, @invalid_attrs)
    refute changeset.valid?
  end
end
