defmodule Trucksu.Mixfile do
  use Mix.Project

  def project do
    [app: :trucksu,
     version: "0.0.13",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     deps: deps,
     dialyzer: [plt_add_apps: [:httpoison, :plug, :phoenix]]
   ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Trucksu, []},
     applications: [:phoenix, :cowboy, :logger, :gettext,
                    :phoenix_ecto, :postgrex, :comeonin, :timex,
                    :phoenix_html, :guardian, :httpoison, :ex_aws,
                    :ex_rated, :ex_statsd, :phoenix_pubsub, :cachex]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.0"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_html, "~> 2.3"},
     {:dialyxir, "~> 0.3.5", only: [:dev]},
     {:timex, "~> 2.1.4"},
     {:cachex, "~> 1.2.2"},
     {:postgrex, "~> 0.11.0"},
     {:timex_ecto, "~> 1.0.4"},
     {:yamerl, github: "yakaz/yamerl"},
     {:countries, github: "SebastianSzturo/countries"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:phoenix_ecto, "~> 3.0.1"},
     {:guardian, git: "https://github.com/ueberauth/guardian.git"},
     {:comeonin, "~> 2.5"},
     {:gettext, "~> 0.9"},
     {:credo, "~> 0.6", only: [:dev, :test]},
     {:httpoison, "~> 0.9.0"},
     {:poison, "~> 1.5"},
     {:ex_aws, "~> 0.4.10"},
     {:mailgun, "~> 0.1.2"},
     {:sweet_xml, "~> 0.5.0"},
     {:ex_rated, "~> 1.2"},
     {:mix_test_watch, "~> 0.2", only: :dev},
     {:ex_statsd, git: "https://github.com/CargoSense/ex_statsd.git"},
     {:cors_plug, "~> 1.1"},
     {:cowboy, "~> 1.0"}]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
