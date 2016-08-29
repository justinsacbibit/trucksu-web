defmodule Trucksu.MeController do
  use Trucksu.Web, :controller
  alias Trucksu.{
    Userpage,
    User,
  }

  plug :scrub_params, "user" when action in [:partial_update]

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    Trucksu.UserController.show(conn, %{"id" => "#{user.id}"})
  end

  def partial_update(conn, %{"user" => %{"old_password" => old_password} = user_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Trucksu.Session.authenticate(user.username, old_password, false) do
      {:ok, user} ->
        # TODO: Invalidate sessions if changing password
        changeset = User.partial_update_changeset(user, user_params)
        case Repo.update changeset do
          {:ok, user} ->
            render(conn, Trucksu.CurrentUserView, "show.json", user: user)
          {:error, changeset} ->
            conn
            |> put_status(400)
            |> render(Trucksu.ErrorView, "400.json", reason: changeset)
        end

      {:error, _reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          "errors" => [
            %{
              "old_password" => "incorrect password",
            }
          ],
        })
    end
  end
  def partial_update(conn, _) do
    conn
    |> put_status(400)
    |> json(%{
      "errors" => [
        %{
          "old_password" => "can't be blank",
        }
      ],
    })
  end

  def upload_userpage(conn, %{"userpage" => userpage}) do
    user = Guardian.Plug.current_resource(conn)

    Userpage.Manager.upload(user.id, userpage)

    conn
    |> json(%{
      "ok" => true,
    })
  end
end
