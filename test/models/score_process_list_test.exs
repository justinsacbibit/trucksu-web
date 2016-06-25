defmodule Trucksu.ScoreProcessListTest do
  use Trucksu.ModelCase

  alias Trucksu.ScoreProcessList

  @valid_attrs %{
    user_id: 1,
    score_id: 2,
    process_list: "ab",
    version: "ba",
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ScoreProcessList.changeset(%ScoreProcessList{}, @valid_attrs)
    assert changeset.valid?
    assert get_change(changeset, :process_list) == "ab"
  end

  test "changeset with invalid attributes" do
    changeset = ScoreProcessList.changeset(%ScoreProcessList{}, @invalid_attrs)
    refute changeset.valid?
  end
end
