defmodule Chat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ChatWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Chat.PubSub},
      # Start the Endpoint (http/https)
      ChatWeb.Endpoint,

      # Start a Drain server
      #Drain.Server,
      # Start a Drain discovery
      #Drain.Discovery,
      # Start the Drain link
      Chat.Repo.Link,
      # -or {Drain.Link, name: Chat.Repo.Link, target: Chat.Repo},
      # Start the Drain repository
      Chat.Repo,
      # -or- {Chat.Repo, link: Chat.Repo.Link},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
