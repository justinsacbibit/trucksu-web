defmodule Trucksu.OsuPagesController do
  use Trucksu.Web, :controller

  def irc_feed(conn, _params) do
    render conn, "response.raw"
  end
end
