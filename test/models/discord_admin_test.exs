defmodule Trucksu.DiscordAdminTest do
  use Trucksu.ModelCase

  alias Trucksu.DiscordAdmin

  @valid_attrs %{discord_id: "42"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = DiscordAdmin.changeset(%DiscordAdmin{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = DiscordAdmin.changeset(%DiscordAdmin{}, @invalid_attrs)
    refute changeset.valid?
  end
end
