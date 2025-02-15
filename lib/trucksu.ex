defmodule Trucksu do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Trucksu.Endpoint, []),
      # Start the Ecto repository
      supervisor(Trucksu.Repo, []),
      # Here you could define other workers and supervisors as children
      # worker(Trucksu.Worker, [arg1, arg2, arg3]),
      worker(Trucksu.AvatarAgent, []),
      worker(Cachex, [:trucksu_cache, [
        default_ttl: :timer.hours(6),
      ]]),
      worker(Cachex, [:userpage_cache, [
        default_ttl: :timer.hours(6),
      ]], id: :userpage_cache),
    ]

    children = if Application.get_env(:trucksu, :env) == :prod do
      children ++ [
        # Periodic tasks
        worker(Trucksu.PeriodicTasks.CalculateMissingPp, []),
      ]
    else
      children
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Trucksu.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Trucksu.Endpoint.config_change(changed, removed)
    :ok
  end
end
