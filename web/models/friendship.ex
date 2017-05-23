defmodule Trucksu.Friendship do
  use Trucksu.Web, :model
  alias Trucksu.User

  schema "friendships" do
    belongs_to :requester, User
    belongs_to :receiver, User

    timestamps()
  end

  @required_fields ~w(requester_id receiver_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:receiver_id, name: :friendships_requester_id_receiver_id_index)
    |> foreign_key_constraint(:receiver_id)
  end
end
