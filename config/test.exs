use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :trucksu, Trucksu.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :trucksu,
  env: :test,
  performance_url: "http://localhost:5000",
  bancho_url: "http://localhost:4002",
  website_url: "http://localhost:4001",
  bot_url: "http://localhost:3000"

# Configure your database
config :trucksu, Trucksu.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres_db",
  password: "postgres_db",
  database: "trucksu_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
