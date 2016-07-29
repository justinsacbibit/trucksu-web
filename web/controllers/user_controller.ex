defmodule Trucksu.UserController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    AvatarAgent,
    Mailer,
    DiscordAdmin,
    User,
    UserStats,
  }

  # admin endpoints
  @admin_endpoints [:ban, :unban, :multiaccounts, :patch]
  plug :check_cookie when action in @admin_endpoints
  plug :check_admin when action in @admin_endpoints
  plug :get_user
  @authenticated_api_endpoints [:upload_avatar]
  plug Guardian.Plug.EnsureAuthenticated, [handler: Trucksu.SessionController] when action in @authenticated_api_endpoints
  plug :scrub_params, "user" when action in [:patch]

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

  defp check_admin(conn, _) do
    discord_id = conn.params["discord_id"]
    case Repo.get_by DiscordAdmin, discord_id: discord_id do
      nil ->
        conn
        |> put_status(403)
        |> json(%{"detail" => "not_admin"})
        |> halt

      _ ->
        conn

    end
  end

  # should be refactored into a generic plug
  defp get_user(conn, _) do
    id_or_username = conn.params["id_or_username"]

    if id_or_username do
      user = case Integer.parse(id_or_username) do
        {id, ""} ->
          Repo.get! User, id
        _ ->
          Repo.one! User.by_username(id_or_username)
      end

      assign(conn, :user, user)
    else
      conn
    end
  end

  def ban(conn, %{"username" => username}) do
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

  def unban(conn, %{"username" => username}) do
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

  def multiaccounts(conn, _) do
    user = conn.assigns[:user]

    filter_map = fn(input) ->
      input
      |> Map.to_list
      |> Enum.map(fn({_id, %User{username: username}}) ->
        username
      end)
      |> Enum.filter(&(&1 != user.username))
    end

    multi_ip_usernames = filter_map.(User.find_multiaccounts_by_ip(user))
    multi_ap_usernames = filter_map.(User.find_multiaccounts_by_access_point(user))

    conn
    |> json(%{
      ip_address: multi_ip_usernames,
      access_point: multi_ap_usernames,
    })
  end

  def patch(conn, %{"user" => user_params}) do
    user = conn.assigns[:user]

    changeset = User.patch_changeset(user, user_params)
    case Repo.update changeset do
      {:ok, user} ->
        render(conn, Trucksu.CurrentUserView, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Trucksu.ErrorView, "400.json", reason: changeset)
    end
  end

  def upload_avatar(conn, %{"avatar_file" => %{path: avatar_path}}) do
    user = Guardian.Plug.current_resource(conn)

    avatar_file_content = File.read!(avatar_path)
    bucket = Application.get_env(:trucksu, :avatar_file_bucket)
    ExAws.S3.put_object!(bucket, "#{user.id}", avatar_file_content)

    AvatarAgent.delete("#{user.id}")

    conn
    |> json(%{
      "ok" => true,
    })
  end

  defmodule ResendVerificationEmailUserNotFoundError do
    @errors [%{usernameOrEmail: "no user exists with that username or email"}]
    defexception plug_status: 404, errors: []
    def exception(_opts) do
      %ResendVerificationEmailUserNotFoundError{errors: @errors}
    end
    def message(_), do: "ResendVerificationEmailUserNotFoundError"
  end

  defmodule ResendVerificationEmailUserAlreadyVerifiedError do
    @errors [%{usernameOrEmail: "already verified"}]
    defexception plug_status: 400, errors: nil
    def exception(_opts) do
      %ResendVerificationEmailUserAlreadyVerifiedError{errors: @errors}
    end
    def message(_), do: "ResendVerificationEmailUserAlreadyVerifiedError"
  end

  def resend_verification_email(conn, %{"email" => email}) do
    user = Repo.get_by User, email: email
    if !user, do: raise ResendVerificationEmailUserNotFoundError, missing: :username
    resend_verification_email_to_user(conn, user)
  end
  def resend_verification_email(conn, %{"username" => username}) do
    user = Repo.one User.by_username(username)
    if !user, do: raise ResendVerificationEmailUserNotFoundError, missing: :email
    resend_verification_email_to_user(conn, user)
  end
  def resend_verification_email(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    if !user, do: raise ResendVerificationEmailUserNotFoundError, missing: :token
    resend_verification_email_to_user(conn, user)
  end

  defp resend_verification_email_to_user(conn, user) do
    if user.email_verified do
      raise ResendVerificationEmailUserAlreadyVerifiedError
    end

    Mailer.send_verification_email(user)

    conn
    |> json(%{
      "ok" => true,
    })
  end

  def show(conn, %{"id" => id}) do
    query = from u in User,
      join: us in assoc(u, :stats),
      left_join: sc in assoc(u, :scores),
      left_join: ob in assoc(sc, :osu_beatmap),
      left_join: obs in assoc(ob, :beatmapset),
      where: us.user_id == ^id
        and (is_nil(sc.id) or
          not is_nil(sc.pp)
          and sc.pass
          and us.game_mode == sc.game_mode),
      preload: [stats: {us, scores: {sc, osu_beatmap: {ob, [beatmapset: obs]}}}],
      order_by: [desc: sc.pp]
    user = Repo.one! query

    # TODO: Filter in SQL using a subquery
    unique_by_md5 = fn %Trucksu.Score{file_md5: file_md5} ->
      file_md5
    end
    stats = for stats <- user.stats do
      scores = stats.scores
      |> Enum.uniq_by(&(unique_by_md5.(&1)))
      |> Enum.take(100)

      rank = Repo.one UserStats.get_rank(user.id, stats.game_mode)

      game_mode = stats.game_mode
      user_id = user.id
      query = from sc in Trucksu.Score,
        join: sc_ in fragment("
          SELECT id
          FROM (
                  SELECT
                     sc.id,
                     user_id,
                     sc.game_mode,
                     row_number()
                     OVER (PARTITION BY sc.file_md5, sc.game_mode
                        ORDER BY score DESC) score_rank
                  FROM scores sc
                  JOIN osu_beatmaps ob
                    on sc.file_md5 = ob.file_md5
                  JOIN users u
                    on sc.user_id = u.id
                  WHERE sc.pass AND NOT u.banned
               ) x
          WHERE user_id = (?) AND score_rank = 1 AND game_mode = (?)
        ", ^user_id, ^game_mode),
          on: sc_.id == sc.id,
        join: u in assoc(sc, :user),
        join: us in assoc(u, :stats),
        join: ob in assoc(sc, :osu_beatmap),
        join: obs in assoc(ob, :beatmapset),
        preload: [osu_beatmap: {ob, [beatmapset: obs]}],
        order_by: [desc: sc.score]
      first_place_scores = Repo.all query

      %{stats | scores: scores, rank: rank, first_place_scores: first_place_scores}
    end
    user = %{user | stats: stats}

    render conn, "user_detail.json", user
  end

  def show_osu_user(conn, %{"user_id" => user_id}) do
    website_url = Application.get_env(:trucksu, :website_url)
    redirect conn, external: "#{website_url}/users/#{user_id}"
  end
end
