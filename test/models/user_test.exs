defmodule Trucksu.UserTest do
  use Trucksu.ModelCase

  alias Trucksu.User

  @valid_attrs %{
    email: "a@b.com",
    username: "Truck Driver",
    password: "abc12",
    password_confirmation: "abc12",
    banned: false,
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
