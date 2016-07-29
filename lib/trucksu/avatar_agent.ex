defmodule Trucksu.AvatarAgent do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def matches?(user_id, etag) do
    Agent.get(__MODULE__, fn(map) ->
      Map.get(map, user_id) == etag
    end)
  end

  def put(user_id, etag) do
    Agent.update(__MODULE__, &Map.put(&1, user_id, etag))
  end

  def delete(user_id) do
    Agent.update(__MODULE__, &Map.delete(&1, user_id))
  end
end
