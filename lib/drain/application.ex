defmodule Drain.Application do
  @moduledoc false

  use Application

  @doc false
  def start(_type, _args) do
    start_options = []

    children = [
      %{
        id: Drain.Gateway,
        start: {Drain.Gateway, :start_link, []}
      },
      %{
        id: :gen_event,
        start: {:gen_event, :start_link, [{:local, Drain}, start_options]},
        modules: :dynamic
      },
      Drain.AggregatorSupervisor
    ]

    case Supervisor.start_link(children, strategy: :rest_for_one, name: Drain.Supervisor) do
      {:ok, sup} ->
        {:ok, sup}

      {:error, _} = error ->
        error
    end
  end

  @doc false
  def start do
    Application.start(:drain)
  end

  def stop do
    Application.stop(:drain)
  end
end
