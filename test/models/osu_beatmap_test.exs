defmodule Trucksu.OsuBeatmapTest do
  use Trucksu.ModelCase

  alias Trucksu.OsuBeatmap

  @valid_attrs %{approved: 42, approved_date: "2010-04-17 14:00:00", artist: "some content", beatmap_id: 42, beatmapset_id: 42, bpm: "120.5", creator: "some content", diff_approach: 42, diff_drain: 42, diff_overall: 42, diff_size: 42, difficultyrating: "120.5", favourite_count: 42, file_md5: "some content", game_mode: 42, genre_id: 42, hit_length: 42, language_id: 42, last_update: "2010-04-17 14:00:00", max_combo: 42, passcount: 42, playcount: 42, source: "some content", tags: "some content", title: "some content", total_length: 42, version: "some content"}
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
