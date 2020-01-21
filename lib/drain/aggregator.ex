defmodule Drain.Aggregator do
  @moduledoc false

  @callback aggregate(%Drain.Event{}) :: :ok

  defmacro __using__(_args) do
    quote do
      @behaviour :gen_event
      @behaviour Drain.Aggregator

      def init(args) do
        {:ok, %{}}
      end

      def handle_event(event, state) do
        apply(__MODULE__, :aggregate, [event])
        {:ok, state}
      rescue
        FunctionClauseError ->
          {:ok, state}
      end

      def handle_call(_event, state) do
        {:ok, :ok, state}
      end
    end
  end
end
