# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :trucksu, Trucksu.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "e2z2aq3mz7GAiStke74ROQ13+nqNmNvXf6EuZNIsK8a8w00VOTLmEpGRBtdKhb5q",
  render_errors: [accepts: ~w(json)],
  pubsub: [name: Trucksu.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :guardian, Guardian,
  issuer: "Trucksu",
  ttl: { 60, :days },
  verify_issuer: true,
  serializer: Trucksu.GuardianSerializer,
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || "e2z2aq3mz7GAiStke74ROQ13+nqNmNvXf6EuZNIsK8a8w00VOTLmEpGRBtdKhb5q"

config :trucksu,
  osu_api_key: System.get_env("OSU_API_KEY"),
  beatmap_file_bucket: System.get_env("BEATMAP_FILE_BUCKET"),
  replay_file_bucket: System.get_env("REPLAY_FILE_BUCKET"),
  avatar_file_bucket: System.get_env("AVATAR_FILE_BUCKET"),
  server_cookie: "a",
  bot_url: System.get_env("BOT_URL") || ""

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

