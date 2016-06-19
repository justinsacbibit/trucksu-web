defmodule Trucksu.OsuBeatmapsetTest do
  use Trucksu.ModelCase

  alias Trucksu.OsuBeatmapset

  @valid_attrs %{
    id: 12,
    approved_date: "2010-04-17 14:00:00",
    artist: "some content",
    bpm: 122.2,
    creator: "some content",
    favorite_count: 42,
    genre_id: 42,
    language_id: 42,
    last_update: "2010-04-17 14:00:00",
    passcount: 42,
    playcount: 42,
    source: "some content",
    tags: "some content",
    title: "some content",
    approved: 2,
    last_check: "2010-04-17 14:00:00",
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = OsuBeatmapset.changeset(%OsuBeatmapset{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = OsuBeatmapset.changeset(%OsuBeatmapset{}, @invalid_attrs)
    refute changeset.valid?
  end
end
