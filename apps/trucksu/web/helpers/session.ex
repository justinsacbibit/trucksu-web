defmodule Trucksu.Session do
  import Ecto.Query, only: [from: 2]
  alias Trucksu.{Repo, User}

  def authenticate(%{"username" => username, "password" => password}, already_hashed \\ false) do
    authenticate(username, password, already_hashed)
  end

  def authenticate(username, password, already_hashed) do
    case Repo.one User.by_username(username) do
      nil ->
        :error
      user ->
        case check_password(user, password, already_hashed) do
          true -> {:ok, user}
          _ -> :error
        end
    end
  end

  defp check_password(user, password, already_hashed) do
    case user do
      nil -> false
      _ ->
        hashed_password = case already_hashed do
          true ->
            password
          false ->
            Trucksu.Hash.md5(password)
        end
        Comeonin.Bcrypt.checkpw(hashed_password, user.encrypted_password)
    end
  end
end

