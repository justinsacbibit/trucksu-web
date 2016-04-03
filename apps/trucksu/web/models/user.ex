defmodule Trucksu.User do
  use Trucksu.Web, :model

  @derive {Poison.Encoder, only: [:id, :username, :email]}

  schema "users" do
    field :username, :string
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true
    has_many :stats, Trucksu.UserStats

    timestamps
  end

  @required_fields ~w(username email password)
  @optional_fields ~w(encrypted_password)

  @doc """
  Creates a query which can fetch a User by username, case insensitive.
  """
  def by_username(username) do
    from u in __MODULE__,
      where: fragment("lower(?)", u.username) == fragment("lower(?)", ^username)
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
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
