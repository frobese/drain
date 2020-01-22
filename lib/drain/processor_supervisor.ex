defmodule Drain.ProcessorSupervisor do
  @moduledoc false

  use Supervisor
  @name Drain.ProcessorSupervisor

  @doc """
  Starts the processor supervisor.
  """
  def start_link(_) do
    case Supervisor.start_link(__MODULE__, [], name: @name) do
      {:ok, _} = ok ->
        for processor <- Application.get_env(:drain, :processors, []) do
          case watch(processor) do
            {:ok, _} ->
              :ok

            {:error, {{:EXIT, exit}, _spec}} ->
              raise "EXIT when installing processor #{inspect(processor)}: " <>
                      Exception.format_exit(exit)

            {:error, error} ->
              raise "ERROR when installing processor #{inspect(processor)}: " <>
                      Exception.format_exit(error)
          end
        end

        ok

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Removes the given `processor`.
  """
  def unwatch(processor) do
    case Supervisor.terminate_child(@name, processor) do
      :ok ->
        _ = Supervisor.delete_child(@name, processor)
        :ok

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Watches the given `processor`.
  """
  def watch(processor) do
    spec = %{
      id: processor,
      start: {Drain.Watcher, :start_link, [{processor, processor}]},
      restart: :transient
    }

    case Supervisor.start_child(@name, spec) do
      {:error, :already_present} ->
        _ = Supervisor.delete_child(@name, processor)
        watch(processor)

      other ->
        other
    end
  end

  @impl true
  def init(children) do
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 30, max_seconds: 3)
  end
end
