defmodule Drain.Event do
  @moduledoc false

  # import Drain.Utils

  @type encoded ::
          {timestamp :: pos_integer(), module_string :: String.t(), tag :: String.t(),
           encoded_event :: String.t()}
  defstruct [
    :uuid,
    :timestamp,
    :tag,
    :data,
    # :application,
    :host,
    :module,
    :version
  ]

  defmacro __using__(opts) do
    stacktrace = __caller_stacktrace__(__CALLER__)

    cond do
      opts[:entity] -> IO.warn("The entity option is deprecated", stacktrace)
      opts[:type] -> IO.warn("The entity option is deprecated", stacktrace)
      true -> :ok
    end

    # type = type(opts, stacktrace)
    version = Macro.expand_once(opts[:version], __CALLER__)

    Module.register_attribute(__CALLER__.module, :__drain_spec__, [])

    quote do
      @__drain_spec__ unquote(Macro.escape(version))

      def publish(tag \\ "", data) when is_binary(tag) do
        unquote(__MODULE__).__publish__(__MODULE__, tag, data, @__drain_spec__)
      end
    end
  end

  @doc false
  def __publish__(module, tag, data, version) do
    %__MODULE__{
      module: module,
      version: version,
      data: data,
      tag: tag,
      # application: :some_app,
      host: node()
    }
    |> Drain.Gateway.publish()
  end

  @doc false
  def __caller_stacktrace__(%Macro.Env{
        module: module,
        function: {func, arity},
        file: file,
        line: line
      }) do
    [{module, func, arity, [file: to_charlist(file), line: line]}]
  end

  @doc false
  def __caller_stacktrace__(%Macro.Env{
        module: module,
        function: nil,
        file: file,
        line: line
      }) do
    [{module, :__MODULE__, 1, [file: to_charlist(file), line: line]}]
  end
end
