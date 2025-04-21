defmodule Pointer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PointerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:pointer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pointer.PubSub},
      # Start a worker by calling: Pointer.Worker.start_link(arg)
      # {Pointer.Worker, arg},
      # Start to serve requests, typically the last entry
      PointerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pointer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PointerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
