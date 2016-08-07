defmodule Trucksu.DiscordAdmin do
  use Trucksu.Web, :model

  schema "discord_admins" do
    field :discord_id, :string

    timestamps
  end

  @required_fields ~w(discord_id)
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
