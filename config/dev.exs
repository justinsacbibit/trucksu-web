use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :trucksu, Trucksu.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    #{Path.expand("webpack.dev.js"), []},
  ]

# Do not include metadata nor timestamps in development logs
# config :logger, :console #, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

config :trucksu, osuparser_url: "http://localhost:3000"

# Configure your database
config :trucksu, Trucksu.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres_db",
  password: "postgres_db",
  database: "trucksu_dev",
  hostname: "localhost",
  pool_size: 10
