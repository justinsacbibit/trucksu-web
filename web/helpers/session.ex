defmodule Trucksu.Session do
  alias Trucksu.{Hash, Repo, User}

  def authenticate(session_params, already_hashed \\ false)
  def authenticate(%{"username" => username, "password" => password}, already_hashed) do
    authenticate(username, password, already_hashed)
  end

  def authenticate(_, _) do
    raise __MODULE__.AuthenticationError
  end

  defmodule AuthenticationError do
    @moduledoc """
    Error raised when unable to authenticate.
    """

    defexception exception: nil, plug_status: 400
  end

  def authenticate(username, password, already_hashed) do
    case Repo.one User.by_username(username) do
      nil ->
        {:error, :username_not_found}
      user ->
        case check_password(user, password, already_hashed) do
          true -> {:ok, user}
          _ -> {:error, :invalid_password}
        end
    end
  end

  defp check_password(user, password, already_hashed) do
    case user do
      nil -> false
      _ ->
        hashed_password = if already_hashed do
          password
        else
          Hash.md5(password)
        end
        Comeonin.Bcrypt.checkpw(hashed_password, user.encrypted_password)
    end
  end
end

