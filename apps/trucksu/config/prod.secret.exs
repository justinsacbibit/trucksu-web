use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :trucksu, Trucksu.Endpoint,
  secret_key_base: "Mn/Y/jEIs8/IR7YT/CLM/qDSak69ZkLdP21aTYMax+71ac/0UEMjPI+Z+CmUuZQI"

# Configure your database
config :trucksu, Trucksu.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "trucksu_prod",
  pool_size: 20
