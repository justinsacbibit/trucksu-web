defmodule Trucksu.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias Trucksu.{Repo, User}

  def for_token(user = %User{}), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  # TODO: Use cache
  def from_token("User:" <> id), do: {:ok, Repo.get(User, String.to_integer(id))}
  def from_token(_), do: {:error, "Unknown resource type"}
end

