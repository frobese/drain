defmodule Drain.MixProject do
  use Mix.Project

  @version "1.0.0-alpha.3"

  def project do
    [
      app: :drain,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def elixirc_paths(env) when env in [:dev, :test] do
    ["test" | elixirc_paths(nil)]
  end

  def elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Drain.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Easy to use Event-Sourcing for Elixir"
  end

  defp docs do
    [
      main: "Drain",
      canonical: "http://hexdocs.pm/drain",
      source_url: "https://github.com/frobese/drain"
    ]
  end

  defp package do
    [
      maintainers: ["Hans Gödeke"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/frobese/drain"
      }
    ]
  end
end
