defmodule Chat.Mixfile do
  use Mix.Project

  def project do
    [
      app: :chat,
      version: "1.5.5",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Chat.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.5"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.2.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},

      # Wake Heroku App. See: https://github.com/dwyl/ping
      {:ping, "~> 1.0.1"},

      # sanitise data to avoid XSS see: https://git.io/fjpGZ
      {:html_sanitize_ex, "~> 1.4"},

      # The rest of the dependendencies are for testing/reporting
      # tracking test coverage
      {:excoveralls, "~> 0.13.0", only: [:test, :dev]},
      # documentation
      {:inch_ex, "~> 2.1.0-rc.1", only: :docs},
      # github.com/dwyl/learn-pre-commit
      {:pre_commit, "~> 0.3.4", only: :dev},

      {:drain, in_umbrella: true}, # for local devel
    ]
  end

  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd yarn --cwd assets install"],
      test: ["test"],
      cover: ["coveralls.json"],
      "cover.html": ["coveralls.html"]
    ]
  end
end
