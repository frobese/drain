defmodule Drain.Gateway do
  @moduledoc false

  use GenServer

  alias Drain.Event

  @gen_event Drain

  def publish(%Event{uuid: nil, timestamp: nil} = event) do
    GenServer.call(__MODULE__, {:"$drain_event", event})
  end

  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

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

  def handle_continue(:init_store, state) do
    state.store.setup()

    {:noreply, state}
  end

  def handle_call({:"$drain_event", event}, _from, %{store: store} = state) do
    event = finalize_event(event)

    :ok = store_event(event, store)

    :gen_event.notify(@gen_event, event)

    {:reply, event, state}
  end

  def finalize_event(event) do
    %Event{event | uuid: UUID.uuid4(), timestamp: :os.system_time(:nanosecond)}
  end

  def store_event(_event, nil) do
    :ok
  end

  def store_event(event, store) do
    event
    |> Event.encode()
    |> store.append()
  end
end
