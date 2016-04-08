ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Trucksu.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Trucksu.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Trucksu.Repo)

