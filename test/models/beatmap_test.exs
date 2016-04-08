defmodule Trucksu.BeatmapTest do
  use Trucksu.ModelCase

  alias Trucksu.Beatmap

  @valid_attrs %{beatmapset_id: 42, file_md5: "some content", filename: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Beatmap.changeset(%Beatmap{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Beatmap.changeset(%Beatmap{}, @invalid_attrs)
    refute changeset.valid?
  end
end
