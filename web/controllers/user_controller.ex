defmodule Trucksu.UserController do
  use Trucksu.Web, :controller
  require Logger
  alias Trucksu.{
    DiscordAdmin,
    User,
  }

  # admin endpoints
  @admin_endpoints [:ban, :unban, :multiaccounts]
  plug :check_cookie when action in @admin_endpoints
  plug :check_admin when action in @admin_endpoints
  plug :get_user

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
        {id, _} ->
          Repo.get! User, id
        _ ->
          Repo.get_by! User, username: id_or_username
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

    multi_usernames = User.find_multiaccounts_by_ip(user)
    |> Map.to_list
    |> Enum.map(fn({_id, %User{username: username}}) ->
      username
    end)

    conn
    |> json(multi_usernames)
  end

  def show(conn, %{"id" => id}) do
    query = from u in User,
      join: us in assoc(u, :stats),
      join: sc in assoc(u, :scores),
      join: ob in assoc(sc, :osu_beatmap),
      join: obs in assoc(ob, :beatmapset),
      where: us.user_id == ^id
        and not is_nil(sc.pp)
        and sc.pass
        and us.game_mode == sc.game_mode,
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

      game_mode = stats.game_mode
      user_id = user.id
      rank = Repo.one from us in Trucksu.UserStats,
        join: s in fragment("
        SELECT game_rank, id
        FROM
          (SELECT
             row_number()
             OVER (
               ORDER BY pp DESC) game_rank,
             user_id, id
           FROM (
             SELECT us.*
             FROM user_stats us
             JOIN users u
               ON u.id = us.user_id
             WHERE u.banned = FALSE
              AND us.game_mode = (?)
           ) sc) sc
        WHERE user_id = (?)
      ", ^game_mode, ^user_id),
        on: s.id == us.id,
        select: s.game_rank

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
                  WHERE sc.pass
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
