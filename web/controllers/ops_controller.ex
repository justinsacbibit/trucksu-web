defmodule Trucksu.OpsController do
  use Trucksu.Web, :controller
  alias Trucksu.{Packet, UserServer, ChannelServer}

  def restart(conn, _params) do
    packet = Packet.server_restart(15000)
    UserServer.Supervisor.enqueue_all(packet)

    :timer.sleep 5000

    Supervisor.stop(UserServer.Supervisor, :normal)
    Supervisor.stop(ChannelServer.Supervisor, :normal)

    render conn, "restart.json"
  end
end
