defmodule Trucksu.RegistrationControllerTest do
  use Trucksu.ConnCase

  test "create user", %{conn: conn} do
    params = %{
      "user" => %{
        "username" => "Trucker",
        "email" => "truck@er.com",
        "password" => "abc12",
        "password_confirmation" => "abc12",
      },
    }
    conn = put_req_header(conn, "content-type", "application/json")
    conn = post conn, "/api/v1/registrations", Poison.encode!(params)
    resp = json_response(conn, 201)

    assert resp["jwt"]
  end
end

