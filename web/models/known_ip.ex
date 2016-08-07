defmodule Trucksu.KnownIp do
  use Trucksu.Web, :model
  alias Trucksu.User

  schema "known_ips" do
    belongs_to :user, User
    field :ip_address, :string

    timestamps
  end

  @required_fields ~w(user_id ip_address)
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
end
