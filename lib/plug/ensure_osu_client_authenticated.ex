defmodule Trucksu.Plugs.EnsureOsuClientAuthenticated do
  require Logger
  import Plug.Conn
  @behaviour Plug
  alias Trucksu.Session

  # TODO: Use opts to determine the username and password keys
  def init(_opts) do
    %{}
  end

  def call(%Plug.Conn{params: %{"u" => username, "h" => password_md5}} = conn, opts) do
    case Session.authenticate(username, password_md5, true) do
      {:error, reason} ->
        Logger.info "#{username} was unable to authenticate: #{reason}"
        handle_error(conn, opts)
      {:ok, user} ->
        assign(conn, :user, user)
    end
  end
  def call(conn, opts) do
    handle_error(conn, opts)
  end

  defp handle_error(%Plug.Conn{params: params} = conn, _opts) do
    conn = conn |> halt
    Trucksu.SessionController.osu_unauthenticated(conn, params)
  end
end

