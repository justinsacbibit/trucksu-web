defmodule Trucksu.Token do
  use Trucksu.Web, :model
  alias Trucksu.User

  schema "tokens" do
    field :value, :string
    belongs_to :user, User

    timestamps
  end

  @required_fields ~w(value user_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:user_id)
  end
end
