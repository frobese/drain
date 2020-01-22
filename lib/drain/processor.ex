defmodule Drain.Processor do
  @moduledoc false

  @callback digest(%Drain.Event{}) :: :ok
  # @callback filter(%Drain.Event{}) :: {:process | :ignore, %Drain.Event{}}

  defmacro __using__(_args) do
    quote do
      @behaviour :gen_event
      @behaviour Drain.Processor

      def init(_args) do
        {:ok, %{}}
      end

      def handle_event(event, state) do
        apply(__MODULE__, :digest, [event])
        {:ok, state}
      rescue
        FunctionClauseError ->
          {:ok, state}
      end

      def handle_call(_event, state) do
        {:ok, :ok, state}
      end

      # defp __filter__(event) do
      #    case apply(__MODULE__, :filter, [args]) do
      #     {:process, _event} = result -> result
      #     {:ignore, _event} = result -> result
      #     _ -> raise "Invalid return of filter function"
      #    end
      #   rescue
      #    FunctionClauseError ->
      #     {:process, state}
      # end

      # def filter(event) do
      #   {:process, event}
      # end

      # defoverridable filter: 1
    end
  end
end
