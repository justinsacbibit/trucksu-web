defmodule Trucksu.EmailTokenTest do
  use Trucksu.ModelCase

  alias Trucksu.EmailToken

  @valid_attrs %{token: "some content", user_id: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = EmailToken.changeset(%EmailToken{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = EmailToken.changeset(%EmailToken{}, @invalid_attrs)
    refute changeset.valid?
  end
end
