defmodule Trucksu.UserGroupTest do
  use Trucksu.ModelCase

  alias Trucksu.UserGroup

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = UserGroup.changeset(%UserGroup{}, @valid_attrs)
    assert changeset.valid?
  end
end
