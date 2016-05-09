defmodule Trucksu.UserController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{DiscordAdmin, User}

  plug :check_cookie when action in [:ban, :unban]

  defp check_cookie(conn, _) do
    cookie = conn.params["c"]
    expected_cookie = Application.get_env(:trucksu, :server_cookie)
    case cookie do
      ^expected_cookie -> conn
      _ ->
        conn
        |> put_status(403)
        |> json(%{"detail" => "invalid_cookie"})
        |> halt
    end
  end

  def ban(conn, %{"username" => username, "discord_id" => discord_id}) do
    case Repo.get_by DiscordAdmin, discord_id: discord_id do
      nil ->

        detail = "not_admin"

        conn
        |> put_status(400)
        |> json(%{"detail" => detail})
      _ ->

        case Repo.one User.by_username(username) do
          nil ->
            detail = "username_not_found"

            conn
            |> put_status(400)
            |> json(%{"detail" => detail})

          %User{banned: true} ->

            detail = "user_already_banned"

            conn
            |> put_status(400)
            |> json(%{"detail" => detail})

          user ->

            changeset = Ecto.Changeset.change(user, %{banned: true})
            case Repo.update changeset do
              {:ok, _} ->
                conn
                |> put_status(200)
                |> json(%{"ok" => true})
              {:error, error} ->

                Logger.error "Error trying to ban user #{user.username}"
                Logger.error inspect error

                conn
                |> put_status(500)
                |> json(%{"detail" => "internal_error"})
            end

        end
    end
  end

  def unban(conn, %{"username" => username, "discord_id" => discord_id}) do
    case Repo.get_by DiscordAdmin, discord_id: discord_id do
      nil ->

        detail = "not_admin"

        conn
        |> put_status(400)
        |> json(%{"detail" => detail})
      _ ->

        case Repo.one User.by_username(username) do
          nil ->
            detail = "username_not_found"

            conn
            |> put_status(400)
            |> json(%{"detail" => detail})

          %User{banned: false} ->

            detail = "user_not_banned"

            conn
            |> put_status(400)
            |> json(%{"detail" => detail})

          user ->

            changeset = Ecto.Changeset.change(user, %{banned: false})
            case Repo.update changeset do
              {:ok, _} ->
                conn
                |> put_status(200)
                |> json(%{"ok" => true})
              {:error, error} ->

                Logger.error "Error trying to unban user #{user.username}"
                Logger.error inspect error

                conn
                |> put_status(500)
                |> json(%{"detail" => "internal_error"})
            end

        end
    end
  end
end

