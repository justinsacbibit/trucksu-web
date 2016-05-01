defmodule Trucksu.Repo.Migrations.RemoveRxApScores do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2]
  require Logger
  alias Trucksu.{Repo, Score}

  def change do
    scores = Repo.all from s in Score,
      where: fragment("mods & (?) <> 0", 128)
        or fragment("mods & (?) <> 0", 2048)
        or fragment("mods & (?) <> 0", 8192)

    for score <- scores do
      Logger.warn "Deleting score: #{inspect score}"
      Repo.delete! score
    end
  end
end
