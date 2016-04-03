defmodule Trucksu.TrucksuController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{Packet, Session, Token, User, UserServer}

  defp get_user_server(user_id, username \\ nil, token \\ nil, force_restart \\ false) do
    case UserServer.whereis(user_id) do
      nil ->
        IO.inspect "starting user server for #{user_id}"
        {:ok, pid} = UserServer.Supervisor.start_user_server(user_id: user_id, username: username, token: token)
        pid
      pid ->
        if force_restart do
          IO.inspect "Restarting user server for #{user_id}"
          UserServer.Supervisor.terminate_child(user_id)
          UserServer.Supervisor.delete_child(user_id)
          {:ok, pid} = UserServer.Supervisor.start_user_server(user_id: user_id, username: username, token: token)
          pid
        else
          pid
        end
    end
  end

  defp ensure_user_server_started(user_id, username, token) do
    get_user_server(user_id, username, token, true)
  end

  def index(conn, _params) do
    osu_token = Plug.Conn.get_req_header(conn, "osu-token")
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    handle_request(conn, body, osu_token)
  end

  defp handle_request(conn, body, []) do
    [username, hashed_password | _] = String.split(body, "\n")

    case Trucksu.Session.authenticate(username, hashed_password, true) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = user |> Guardian.encode_and_sign(:token)

        ensure_user_server_started(user.id, user.username, jwt)

        render prepare_conn(conn, jwt), "response.raw", data: login_packets(user)
      :error ->
        IO.inspect Packet.login_failed
        render prepare_conn(conn), "response.raw", data: Packet.login_failed
    end
  end

  defp handle_request(conn, stacked_packets, [osu_token]) do
    data = case Guardian.decode_and_verify(osu_token) do
      {:ok, claims} ->

        # TODO: Consider preventing SQL queries when it is a pong packet
        #       and the packet queue is empty
        {:ok, user} = Guardian.serializer.from_token(claims["sub"])
        get_user_server(user.id, user.username, osu_token)

        data = Packet.Decoder.decode_packets(stacked_packets)
        |> Enum.reduce(<<>>, fn({packet_id, data}, acc) ->
          acc <> handle_packet(packet_id, data, user)
        end)

        packet_queue = get_user_server(user.id) |> GenServer.call(:dequeue_all)
        data <> Enum.reduce(packet_queue, <<>>, fn(packet, acc) ->
          acc <> packet
        end)

      {:error, _reason} ->
        Packet.login_failed
    end

    render prepare_conn(conn, osu_token), "response.raw", data: data
  end

  defp handle_packet(0, data, user) do
    Logger.debug "Handling changeAction: data: #{inspect data}, user id: #{user.id}"
    # TODO: Possibly enqueue user panel as well..

    UserServer.whereis(user.id)
    |> GenServer.cast({:change_action, data})

    packet = Packet.user_stats(user)
    UserServer.Supervisor.enqueue_all(packet)
    <<>>
  end

  defp handle_packet(1, data, user) do
    packet = Packet.send_message(user.username, data[:message], data[:to], user.id)
    # UserServer.Supervisor.enqueue_all(packet, exclude: [user.id])
    <<>>
  end

  defp handle_packet(2, data, user) do
    packet = Packet.logout(user.id)
    UserServer.Supervisor.enqueue_all(packet)

    <<>>
  end

  defp handle_packet(3, data, user) do
    IO.puts "Unhandled requestStatusUpdate"
    <<>>
  end

  defp handle_packet(4, _data, _user) do
    <<>>
  end

  defp handle_packet(63, data, user) do
    IO.puts "Handling channel join"
    Packet.channel_join_success(data[:channel])
  end

  defp handle_packet(68, data, user) do
    IO.puts "Unhandled beatmapInfoRequest"
    IO.inspect data
    <<>>
  end

  # client_channelPart
  defp handle_packet(78, [channel: channel], user) do
    Logger.warn "Handling channel part"
    <<>>
  end

  defp handle_packet(85, data, user) do
    # userStatsRequest

    # No idea why the integer is coming out unsigned, this is -1 in signed 32 bit
    unless data[:user_id] == 4294967295 do
      case Repo.get User, data[:user_id] do
        nil ->
          <<>>
        user ->
          Packet.user_stats(user)
      end

    end
  end

  defp handle_packet(packet_id, data, user) do
    IO.puts "Unhandled packet #{packet_id}"
    IO.inspect data
    <<>>
  end

  defp prepare_conn(conn, cho_token \\ "") do
    conn
    |> Plug.Conn.put_resp_header("cho-token", cho_token)
    |> Plug.Conn.put_resp_header("cho-protocol", "19")
    |> Plug.Conn.put_resp_header("Keep-Alive", "timeout=5, max=100")
    |> Plug.Conn.put_resp_header("Connection", "keep-alive")
    |> Plug.Conn.put_resp_header("Content-Type", "text/html; charset=UTF-8")
    |> Plug.Conn.put_resp_header("Vary", "Accept-Encoding")
  end

  defp login_packets(user) do
    Packet.silence_end_time(0)
    <> Packet.user_id(user.id)
    <> Packet.protocol_version
    <> Packet.user_supporter_gmt(true, true)
    <> Packet.user_panel(user)
    <> Packet.user_stats(user)
    <> Packet.channel_info_end
    <> Packet.channel_join_success("#osu")
    <> Packet.channel_join_success("#announce")
    <> Packet.channel_info("#osu")
    <> Packet.channel_info("#announce")
    # TODO: Dynamically add channel info
    <> Packet.friends_list(user)
    # TODO: Menu icon
    # TODO: Login notification
    # TODO: Other users' user panels, stats
    <> Packet.online_users
  end
end

