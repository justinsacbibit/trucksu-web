defmodule Trucksu.ScoreProcessList do
  use Trucksu.Web, :model

  schema "score_process_lists" do
    belongs_to :user, Trucksu.User
    belongs_to :score, Trucksu.Score
    field :process_list, :string
    field :version, :string

    timestamps
  end

  @required_fields ~w(user_id score_id process_list version)
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
end

