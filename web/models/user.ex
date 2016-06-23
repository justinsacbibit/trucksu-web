defmodule Trucksu.User do
  use Trucksu.Web, :model
  alias Trucksu.Repo

  @derive {Poison.Encoder, only: [
    :id,
    :username,
    :email,
  ]}

  schema "users" do
    field :username, :string
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true
    has_many :stats, Trucksu.UserStats
    has_many :scores, Trucksu.Score
    field :country, :string
    field :banned, :boolean, default: false

    has_many :friendships, Trucksu.Friendship, foreign_key: :requester_id
    has_many :friends, through: [:friendships, :receiver]

    has_many :known_ips, Trucksu.KnownIp
    has_many :access_points, Trucksu.OsuUserAccessPoint

    timestamps
  end

  @required_fields ~w(username email password)
  @optional_fields ~w(encrypted_password banned)

  @doc """
  Creates a query which can fetch a User by username, case insensitive.
  """
  def by_username(username) do
    from u in __MODULE__,
      where: fragment("lower(?)", u.username) == fragment("lower(?)", ^username)
  end

  @doc """
  Builds a Map of users who seem to be multiaccounts for the given user, by access point.
  The map returned maps user ids to user structs.

  Does a depth-first search on a graph where a user is a node and an edge exists between
  users if they share at least one access point.

  """
  def find_multiaccounts_by_access_point(%__MODULE__{id: id} = user, accounts_so_far \\ %{}) do
    if Map.has_key?(accounts_so_far, id) do
      # base case
      accounts_so_far
    else
      user = Repo.preload user, :access_points
      accounts_so_far = Map.put(accounts_so_far, id, user)

      Enum.reduce(user.access_points, accounts_so_far, fn(access_point, accounts_so_far) ->
        %{unique_md5: unique_md5, disk_md5: disk_md5} = access_point
        users_with_same_access_point = Repo.all from u in __MODULE__,
          join: ap in assoc(u, :access_points),
          where: ap.unique_md5 == ^unique_md5
            or ((not is_nil(fragment("(?)::bytea", ^disk_md5)) and not is_nil(ap.disk_md5)) and ap.disk_md5 == ^disk_md5)

        Enum.reduce(users_with_same_access_point, accounts_so_far, fn(user_with_same_access_point, accounts_so_far) ->
          Map.merge(accounts_so_far, find_multiaccounts_by_access_point(user_with_same_access_point, accounts_so_far))
        end)
      end)
    end
  end

  @doc """
  Builds a Map of users who seem to be multiaccounts for the given user, by IP address.
  The map returned maps user ids to user structs.

  Does a depth-first search on a graph where a user is a node and an edge exists between
  users if they share at least one IP address.

  """
  def find_multiaccounts_by_ip(%__MODULE__{id: id} = user, accounts_so_far \\ %{}) do
    if Map.has_key?(accounts_so_far, id) do
      # base case
      accounts_so_far
    else
      user = Repo.preload user, :known_ips
      accounts_so_far = Map.put(accounts_so_far, id, user)

      Enum.reduce(user.known_ips, accounts_so_far, fn(known_ip, accounts_so_far) ->
        known_ip_address = known_ip.ip_address
        users_with_same_ip = Repo.all from u in __MODULE__,
          join: ip in assoc(u, :known_ips),
          where: ip.ip_address == ^known_ip_address

        Enum.reduce(users_with_same_ip, accounts_so_far, fn(user_with_same_ip, accounts_so_far) ->
          Map.merge(accounts_so_far, find_multiaccounts_by_ip(user_with_same_ip, accounts_so_far))
        end)
      end)
    end
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_format(:username, ~r/^[-_\[\]A-Za-z0-9 ]+$/)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 5)
    |> validate_confirmation(:password, message: "Password does not match")
    |> unique_constraint(:email, message: "Email already taken", name: :users_lower_email_index)
    |> unique_constraint(:username, message: "Username already taken", name: :users_lower_username_index)
    |> generate_encrypted_password
  end

  defp generate_encrypted_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        hashed_password = Trucksu.Hash.md5(password)
        put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(hashed_password))
      _ ->
        changeset
    end
  end
end
