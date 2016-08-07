defmodule Trucksu.OsuUserAccessPoint do
  use Trucksu.Web, :model

  schema "osu_user_access_points" do
    field :osu_md5, :binary
    field :mac_md5, :binary
    field :unique_md5, :binary
    field :disk_md5, :binary
    belongs_to :user, Trucksu.User

    timestamps
  end

  @required_fields ~w(osu_md5 mac_md5 unique_md5 user_id)
  @optional_fields ~w(disk_md5)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    base_16_validator = fn(key, base16) ->
      case Base.decode16(base16, case: :lower) do
        {:ok, _} ->
          []
        _ ->
          [{key, "must be valid base16"}]
      end
    end
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_change(:osu_md5, base_16_validator)
    |> validate_change(:mac_md5, base_16_validator)
    |> validate_change(:unique_md5, base_16_validator)
    |> validate_change(:disk_md5, base_16_validator)
    |> update_change_if_valid(:osu_md5, &Base.decode16!(&1, case: :lower))
    |> update_change_if_valid(:mac_md5, &Base.decode16!(&1, case: :lower))
    |> update_change_if_valid(:unique_md5, &Base.decode16!(&1, case: :lower))
    |> update_change_if_valid(:disk_md5, &Base.decode16!(&1, case: :lower))
    |> unique_constraint(:osu_md5, name: :osu_user_access_points_unique_index)
  end

  defp update_change_if_valid(%{valid?: false} = changeset, _, _), do: changeset
  defp update_change_if_valid(changeset, field, validator) do
    update_change(changeset, field, validator)
  end
end
