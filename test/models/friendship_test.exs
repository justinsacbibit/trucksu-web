defmodule Trucksu.FriendshipTest do
  use Trucksu.ModelCase

  alias Trucksu.Friendship

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Friendship.changeset(%Friendship{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Friendship.changeset(%Friendship{}, @invalid_attrs)
    refute changeset.valid?
  end
end
