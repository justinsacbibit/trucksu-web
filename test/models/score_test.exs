defmodule Trucksu.ScoreTest do
  use Trucksu.ModelCase

  alias Trucksu.Score

  @valid_attrs %{
    accuracy: 120.5,
    count_100: 42,
    count_300: 42,
    count_50: 42,
    file_md5: "abc",
    full_combo: 42,
    game_mode: 42,
    geki_count: 42,
    katu_count: 42,
    max_combo: 42,
    miss_count: 42,
    mods: 42,
    pass: true,
    score: 42,
    time: "some content",
    user_id: 3,
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Score.changeset(%Score{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Score.changeset(%Score{}, @invalid_attrs)
    refute changeset.valid?
  end
end
