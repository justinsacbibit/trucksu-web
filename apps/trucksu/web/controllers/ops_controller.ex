defmodule Trucksu.OpsController do
  use Trucksu.Web, :controller
  alias Trucksu.{Packet, UserServer}

  def restart(conn, _params) do
    packet = Packet.server_restart(5000)
    UserServer.Supervisor.enqueue_all(packet)

    render conn, "restart.json"
  end
end
