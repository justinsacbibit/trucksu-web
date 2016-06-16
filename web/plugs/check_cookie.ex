defmodule Trucksu.Plugs.CheckCookie do
  @moduledoc """
  Checks an incoming request for a secure server cookie.

  Args:
    - `param_name`: Key that maps to the incoming server cookie
    - `cookie_name`: Key that maps to the server cookie in the app configuration
  """
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, opts) do
    cookie = conn.params[opts[:param_name] || "c"]
    expected_cookie = Application.get_env(:trucksu, opts[:cookie_name])
    case cookie do
      ^expected_cookie -> conn
      _ ->
        conn
        |> Plug.Conn.put_status(403)
        |> Phoenix.Controller.json(%{"detail" => "invalid_cookie"})
        |> Plug.Conn.halt
    end
  end
end

