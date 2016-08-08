defmodule Trucksu.UserController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    Friendship,
    AvatarAgent,
    Mailer,
    Score,
    DiscordAdmin,
    OsuBeatmap,
    User,
    UserStats,
    PerformanceGraph,
  }

  # admin endpoints
  @admin_endpoints [:ban, :unban, :multiaccounts, :patch]
  plug :check_cookie when action in @admin_endpoints
  plug :check_admin when action in @admin_endpoints
  plug :get_user
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

  def friends_index(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    user_id = user.id

    query = from f in Friendship,
      join: u in assoc(f, :receiver),
      where: f.requester_id == ^user_id,
      select: u
    friends = Repo.all query

    friend_maps = friends
    |> Enum.map(&process_friend_to_task(&1, user_id))
    |> Enum.map(&Task.await/1)

    render(conn, "friends.json", friends: friend_maps)
  end

  defp process_friend_to_task(friend, logged_in_user_id) do
    Task.async(fn ->
      friend_id = friend.id
      reverse_query = from f in Friendship,
        where: f.requester_id == ^friend_id
        and f.receiver_id == ^logged_in_user_id
      reverse_friendship = Repo.one reverse_query
      is_mutual = not is_nil(reverse_friendship)

      %{id: friend.id, username: friend.username, mutual: is_mutual}
    end)
  end

  def add_friend(conn, %{"friend_id" => friend_id}) do
    user = Guardian.Plug.current_resource(conn)

    changeset = Friendship.changeset(%Friendship{}, %{
      requester_id: user.id,
      receiver_id: friend_id,
    })

    case Repo.insert changeset do
      {:error, %{errors: errors} = changeset} ->
        fun = fn({key, {message, _}}) ->
          key == :receiver_id and message == "has already been taken"
        end
        already_friends = Enum.any?(errors, fun)
        if already_friends do
          conn
          |> json(%{
            "ok" => true,
            "had_friendship" => true,
          })
        else
          conn
          |> put_status(400)
          |> render(Trucksu.ErrorView, "400.json", reason: changeset)
        end
      _ ->
        conn
        |> json(%{
          "ok" => true,
          "had_friendship" => false,
        })
    end
  end
  def add_friend(conn, _) do
    conn
    |> put_status(400)
    |> render(Trucksu.ErrorView, "400.json", reason: %{
      errors: [
        {"friend_id", {"can't be blank", nil}},
      ]
    })
  end

  def remove_friend(conn, %{"friend_id" => friend_id}) do
    user = Guardian.Plug.current_resource(conn)

    user_id = user.id
    query = from f in Friendship,
      where: f.requester_id == ^user_id
        and f.receiver_id == ^friend_id
    friendship = Repo.one query

    if friendship do
      Repo.delete! friendship
    end

    conn
    |> json(%{
      "ok" => true,
      "had_friendship" => not is_nil(friendship),
    })
  end
  def remove_friend(conn, _) do
    conn
    |> put_status(400)
    |> render(Trucksu.ErrorView, "400.json", reason: %{
      errors: [
        {"friend_id", {"can't be blank", nil}},
      ]
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
    logged_in_user = Guardian.Plug.current_resource(conn)
    friendship_type_task = Task.async(fn ->
      if logged_in_user do
        logged_in_user_id = logged_in_user.id

        friendship_query = from f in Friendship,
          where: f.requester_id == ^logged_in_user_id
            and f.receiver_id == ^id
        friendship_task = Task.async(fn -> Repo.one friendship_query end)

        reverse_query = from f in Friendship,
          where: f.requester_id == ^id
            and f.receiver_id == ^logged_in_user_id
        reverse_friendship_task = Task.async(fn -> Repo.one reverse_query end)

        friendship = Task.await(friendship_task)
        is_friend = not is_nil(friendship)

        reverse_friendship = Task.await(reverse_friendship_task)
        is_mutual = is_friend and not is_nil(reverse_friendship)

        cond do
          is_mutual -> "mutual"
          is_friend -> "friend"
          true -> "none"
        end
      else
        nil
      end
    end)

    user_task = Task.async(fn ->
      user = Repo.get!(User, id)
      |> Repo.preload(:groups)

      game_mode_range = 0..3
      stats = game_mode_range
      |> Enum.map(fn(game_mode) ->
        Task.async(fn ->
          score_query = from sc in Score,
            where: sc.user_id == ^id
              and sc.game_mode == ^game_mode
              and sc.pass
              and not is_nil(sc.pp),
            order_by: [desc: sc.pp]

          scores_task = create_scores_task(score_query)

          us_query = from us in UserStats,
            where: us.user_id == ^id
              and us.game_mode == ^game_mode
          stats_for_game_mode = Repo.one!(us_query)

          user_id = user.id
          rank_task = Task.async(fn ->
            Repo.one UserStats.get_rank(user_id, game_mode)
          end)

          query = from sc in score_query,
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
              on: sc_.id == sc.id

          first_place_scores_task = create_scores_task(query)

          %{stats_for_game_mode |
            scores: Task.await(scores_task),
            rank: Task.await(rank_task),
            first_place_scores: Task.await(first_place_scores_task),
          }
        end)
      end)
      |> Enum.map(&Task.await/1)
      user = %{user | stats: stats}
      user
    end)

    graphs_task = Task.async(fn ->
      # TODO: Support other game modes
      game_mode = 0
      pp_graph = PerformanceGraph.Server.get(id, game_mode)
      graphs = %{
        game_mode => %{
          pp: pp_graph,
        },
        1 => %{},
        2 => %{},
        3 => %{},
      }
      graphs
    end)

    render conn, "user_detail.json",
      user: Task.await(user_task),
      friendship: Task.await(friendship_type_task),
      graphs: Task.await(graphs_task)
  end

  defp create_scores_task(query) do
    Task.async(fn ->
      Repo.all(query)
      |> Repo.preload(osu_beatmap: [:beatmapset])
      |> Enum.uniq_by(fn(score) -> score.file_md5 end)
      |> Enum.take(100)
    end)
  end

  def show_osu_user(conn, %{"user_id" => user_id}) do
    website_url = Application.get_env(:trucksu, :website_url)
    redirect conn, external: "#{website_url}/users/#{user_id}"
  end
end
