defmodule Trucksu.Plug.IncrementStat do
  require Logger
  @behaviour Plug

  def init(opts) do
    Enum.into(opts, %{})
  end

  def call(conn, %{name: name}) do
    ExStatsD.increment(name)
    conn
  end
end
