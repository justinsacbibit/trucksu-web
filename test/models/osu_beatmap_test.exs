defmodule Trucksu.OsuBeatmapTest do
  use Trucksu.ModelCase

  alias Trucksu.OsuBeatmap

  @valid_attrs %{
    id: 1,
    beatmapset_id: 42,
    diff_approach: 42,
    diff_drain: 42,
    diff_overall: 42,
    diff_size: 42,
    difficultyrating: "120.5",
    file_md5: "some content",
    game_mode: 0,
    hit_length: 42,
    max_combo: 42,
    passcount: 42,
    playcount: 42,
    total_length: 42,
    version: "some content",
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = OsuBeatmap.changeset(%OsuBeatmap{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = OsuBeatmap.changeset(%OsuBeatmap{}, @invalid_attrs)
    refute changeset.valid?
  end
end
