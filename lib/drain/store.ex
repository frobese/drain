defmodule Drain.Store do
  @moduledoc false

  alias Drain.Event

  @callback setup() :: :ok | :error
  @callback append(Event.encoded()) :: :ok | :error
  @callback get(
              timestamp :: pos_integer() | nil,
              modules :: list(String.t()) | nil,
              tags :: list(String.t()) | nil
            ) :: list(Event.encoded())

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      def __drain_store__, do: true
    end
  end
end
