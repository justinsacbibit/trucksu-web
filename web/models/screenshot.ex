defmodule Trucksu.Screenshot do
  use Trucksu.Web, :model
  alias Trucksu.User

  schema "screenshots" do
    belongs_to :user, User

    timestamps
  end

  @required_fields ~w(user_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def new(user_id) do
    changeset(%__MODULE__{}, %{user_id: user_id})
  end
end
