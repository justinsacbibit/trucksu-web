defmodule Trucksu.AvatarControllerTest do
  use Trucksu.ConnCase
  import Mock
  alias Trucksu.FileRepository

  defp default_avatar do
    # not really ideal
    default_path = "web/static/images/default_avatar.jpg"
    {:ok, content} = File.read(default_path)
    content
  end

  test "returns the default avatar", %{conn: conn} do
    conn = get conn, avatar_path(conn, :show, "-1")

    expected = default_avatar()
    assert response(conn, 200) == expected
  end

  test_with_mock "returns the default avatar when avatar is not found", FileRepository,
    [get_file: fn(:avatar_file_bucket, "2") -> {:error, :not_found} end] do
    conn = get conn, avatar_path(conn, :show, "2")

    expected = default_avatar()
    assert response(conn, 200) == expected
  end

  test_with_mock "returns the default avatar when an error occurs trying to fetch the avatar", FileRepository,
    [get_file: fn(:avatar_file_bucket, "2") -> {:error, :error} end] do
    conn = get conn, avatar_path(conn, :show, "2")

    expected = default_avatar()
    assert response(conn, 200) == expected
  end

  test_with_mock "gets avatar from file repository", FileRepository,
    [get_file: fn(:avatar_file_bucket, "3") -> {:ok, "avatar content"} end] do
    conn = get conn, avatar_path(conn, :show, "3")
    assert response(conn, 200) == "avatar content"
  end
end

