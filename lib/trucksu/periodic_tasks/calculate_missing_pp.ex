defmodule Trucksu.PeriodicTasks.CalculateMissingPp do
  @moduledoc """
  Takes care of periodically calculating pp for scores with a nil pp value.
  """
  require Logger
  alias Trucksu.Performance

  def start_link do
    Task.start_link(&work/0)
  end

  @sleep :timer.hours(24)

  defp work do
    Performance.calculate_missing()

    :timer.sleep @sleep

    work()
  end
end
