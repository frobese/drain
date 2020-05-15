defmodule Drain.Gateway do
  @moduledoc false

  use GenServer

  import Drain.Utils

  alias Drain.Event

  @gen_event Drain

  @doc false
  def publish(%Event{uuid: nil, timestamp: nil} = event) do
    GenServer.call(__MODULE__, {:"$drain_event", event})
  end

  @doc false
  def get(timestamp, modules, tags) do
    GenServer.call(__MODULE__, {:"$drain_get_events", timestamp, modules, tags})
  end

  @doc false
  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    case Application.get_env(:drain, :store) do
      nil ->
        IO.warn("Drain is used without a store!")

        {:ok, %{store: nil}}

      store ->
        if Code.ensure_compiled?(store) and
             function_exported?(store, :__drain_store__, 0) and
             store.__drain_store__() do
          {:ok, %{store: store}, {:continue, :init_store}}
        else
          {:stop, "#{store} is not a valid Drain store"}
        end
    end
  end

  @impl true
  def handle_continue(:init_store, state) do
    state.store.setup()

    {:noreply, state}
  end

  @impl true
  def handle_call({:"$drain_event", event}, _from, %{store: store} = state) do
    event = finalize_event(event)

    :ok = store_event(event, store)

    :gen_event.notify(@gen_event, event)

    {:reply, event, state}
  end

  def handle_call(
        {:"$drain_get_events", timestamp, modules, tags},
        _from,
        %{store: store} = state
      ) do
    {:reply, {:os.system_time(:nanosecond), get_events(timestamp, modules, tags, store)}, state}
  end

  def finalize_event(event) do
    %Event{event | uuid: UUID.uuid4(), timestamp: :os.system_time(:nanosecond)}
  end

  defp store_event(_event, nil) do
    :ok
  end

  defp store_event(event, store) do
    event
    |> encode_event()
    |> store.append()
  end

  defp get_events(_timestamp, _modules, _tags, nil) do
    []
  end

  defp get_events(timestamp, modules, tags, store) do
    store.get(timestamp, modules, tags)
    |> Enum.map(fn decoded ->
      case decode_event(decoded) do
        {:ok, event} -> event
        _ -> []
      end
    end)
    |> List.flatten()
  end
end
