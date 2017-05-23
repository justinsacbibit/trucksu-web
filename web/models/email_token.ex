defmodule Trucksu.EmailToken do
  use Trucksu.Web, :model

  @token_length 20

  schema "email_tokens" do
    field :token, :string
    belongs_to :user, Trucksu.User

    timestamps()
  end

  @required_fields ~w(token user_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def new(user) do
    changeset(%__MODULE__{}, %{
      token: :crypto.strong_rand_bytes(@token_length) |> Base.url_encode64 |> binary_part(0, @token_length),
      user_id: user.id,
    })
  end
end
