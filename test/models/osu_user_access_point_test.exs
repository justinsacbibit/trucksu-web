defmodule Trucksu.OsuUserAccessPointTest do
  use Trucksu.ModelCase

  alias Trucksu.OsuUserAccessPoint

  @valid_attrs %{
    mac_md5: "dabc",
    osu_md5: "abcd",
    unique_md5: "abcd",
    user_id: 1,
  }
  @invalid_disk_md5 %{
    disk_md5: "ga",
  }
  @nil_disk_md5 %{
    disk_md5: nil,
  }
  @invalid_mac_md5 %{
    mac_md5: "ga",
  }
  @invalid_osu_md5 %{
    osu_md5: "ga",
  }
  @invalid_unique_md5 %{
    unique_md5: "ga",
  }

  test "changeset with valid attributes" do
    changeset = OsuUserAccessPoint.changeset(%OsuUserAccessPoint{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with nil disk_md5" do
    params = Map.merge(@valid_attrs, @nil_disk_md5)
    changeset = OsuUserAccessPoint.changeset(%OsuUserAccessPoint{}, params)
    assert changeset.valid?
  end

  test "changeset decodes osu_md5 base16" do
    changeset = OsuUserAccessPoint.changeset(%OsuUserAccessPoint{}, @valid_attrs)
    {:ok, osu_md5} = fetch_change(changeset, :osu_md5)
    assert osu_md5 == Base.decode16!(@valid_attrs[:osu_md5], case: :lower)
  end

  test "changeset with invalid disk_md5" do
    params = Map.merge(@valid_attrs, @invalid_disk_md5)
    changeset = OsuUserAccessPoint.changeset(%OsuUserAccessPoint{}, params)
    refute changeset.valid?
  end

  test "changeset with invalid mac_md5" do
    params = Map.merge(@valid_attrs, @invalid_mac_md5)
    changeset = OsuUserAccessPoint.changeset(%OsuUserAccessPoint{}, params)
    refute changeset.valid?
  end

  test "changeset with invalid osu_md5" do
    params = Map.merge(@valid_attrs, @invalid_osu_md5)
    changeset = OsuUserAccessPoint.changeset(%OsuUserAccessPoint{}, params)
    refute changeset.valid?
  end

  test "changeset with invalid unique_md5" do
    params = Map.merge(@valid_attrs, @invalid_unique_md5)
    changeset = OsuUserAccessPoint.changeset(%OsuUserAccessPoint{}, params)
    refute changeset.valid?
  end
end
