defmodule Trucksu.UserGroup do
  use Trucksu.Web, :model

  schema "user_groups" do
    belongs_to :user, Trucksu.User
    belongs_to :group, Trucksu.Group

    timestamps()
  end

  @required_fields ~w()
  @optional_fields ~w(group_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
