defmodule Drain.AggregatorSupervisor do
  @moduledoc false

  use Supervisor
  @name Drain.AggregatorSupervisor

  @doc """
  Starts the aggregator supervisor.
  """
  def start_link(_) do
    case Supervisor.start_link(__MODULE__, [], name: @name) do
      {:ok, _} = ok ->
        for aggregator <- Application.get_env(:drain, :aggregators, []) do
          case watch(aggregator) do
            {:ok, _} ->
              :ok

            {:error, {{:EXIT, exit}, _spec}} ->
              raise "EXIT when installing aggregator #{inspect(aggregator)}: " <>
                      Exception.format_exit(exit)

            {:error, error} ->
              raise "ERROR when installing aggregator #{inspect(aggregator)}: " <>
                      Exception.format_exit(error)
          end
        end

        ok

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Removes the given `aggregator`.
  """
  def unwatch(aggregator) do
    case Supervisor.terminate_child(@name, aggregator) do
      :ok ->
        _ = Supervisor.delete_child(@name, aggregator)
        :ok

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Watches the given `aggregator`.
  """
  def watch(aggregator) do
    spec = %{
      id: aggregator,
      start: {Drain.Watcher, :start_link, [{aggregator, aggregator}]},
      restart: :transient
    }

    case Supervisor.start_child(@name, spec) do
      {:error, :already_present} ->
        _ = Supervisor.delete_child(@name, aggregator)
        watch(aggregator)

      other ->
        other
    end
  end

  @impl true
  def init(children) do
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 30, max_seconds: 3)
  end
end
