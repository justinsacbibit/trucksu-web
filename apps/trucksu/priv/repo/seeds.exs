# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Trucksu.Repo.insert!(%Trucksu.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Trucksu.{Repo, User}

def random_password do
  length = 8
  :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
end

Repo.transaction fn ->
  changeset = User.changeset %User{}, %{
    username: "TruckBot",
    password: random_password,
    email: "truck@bot.com",
  }
  truckbot = Repo.insert! changeset

  %User{id: 1} = truckbot

  changeset = User.changeset %User{}, %{
    username: "TruckLord",
    password: random_password,
    email: "truck@lord.com",
  }
  trucklord = Repo.insert! changeset

  %User{id: 2} = trucklord
end
