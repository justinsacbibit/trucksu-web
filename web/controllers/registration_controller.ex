defmodule Trucksu.RegistrationController do
  use Trucksu.Web, :controller

  alias Trucksu.{Repo, User, UserStats}

  plug :scrub_params, "user" when action in [:create]

  def create(conn, %{"user" => user_params}) do

    changeset = User.changeset(%User{}, user_params)

    result = Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, user} ->
          Enum.each [0, 1, 2, 3], fn(mode) ->
            Repo.insert! UserStats.create_for_user(user, mode)
          end

          {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

          conn
          |> put_status(:created)
          |> render(Trucksu.SessionView, "show.json", jwt: jwt, user: user)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(Trucksu.RegistrationView, "error.json", changeset: changeset)
      end
    end)

    case result do
      {:ok, rendered} ->
        rendered

      _ ->
        # Makes no sense, but in the event of an error, Phoenix sends the correct
        # error json. This seems to get rid of the Plug.Conn.NotSentError
        conn
        |> put_status(:unprocessable_entity)
        |> html("")
    end
  end
end

