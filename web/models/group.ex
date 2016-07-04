defmodule Trucksu.Group do
  use Trucksu.Web, :model

  @trucksu_team_id 1
  @global_moderation_team_id 2
  @development_team_id 3

  schema "groups" do
    field :name, :string
    many_to_many :users, Trucksu.User, join_through: Trucksu.UserGroup
  end

  @required_fields ~w(name)
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

  def trucksu_team_id, do: @trucksu_team_id
  def global_moderation_team_id, do: @global_moderation_team_id
  def development_team_id, do: @development_team_id
end
