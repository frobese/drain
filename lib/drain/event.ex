defmodule Drain.Event do
  @moduledoc false

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
    stacktrace = caller_stacktrace(__CALLER__)

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

      def publish(tag \\ "", data) when is_binary(tag) and is_map(data) do
        unquote(__MODULE__).__publish__(__MODULE__, tag, data, @__drain_spec__)
      end
    end
  end

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

  def encode(%__MODULE__{} = event) do
    {event.timestamp, Atom.to_string(event.module), event.tag,
     Base.encode64(:erlang.term_to_binary(event))}
  end

  def decode({timestamp, module_string, tag, encoded_event}) do
    with module <- String.to_existing_atom(module_string),
         {:ok, binary_event} <- Base.decode64(encoded_event),
         %__MODULE__{timestamp: ^timestamp, module: ^module, tag: ^tag} = event <-
           :erlang.binary_to_term(binary_event, [:safe]) do
      {:ok, event}
    else
      %__MODULE__{} ->
        {:error, :integrity_error}

      :error ->
        {:error, :encoding_error}
    end
  rescue
    ArgumentError ->
      {:error, :integrity_error}
  end

  # defp type(opts, stacktrace) do
  #   type = opts[:type]

  #   if(type in @types) do
  #     type
  #   else
  #     IO.warn("Expected a type of " <> Enum.join(@types, ", "), stacktrace)
  #   end
  # end

  # defp entity(opts, caller, stacktrace) do
  #   entity = opts[:entity]

  #   entity =
  #     if Macro.validate(entity) == :ok do
  #       Macro.expand_once(entity, caller)
  #     else
  #       entity
  #     end

  #   cond do
  #     is_atom(entity) ->
  #       entity

  #     is_nil(entity) ->
  #       IO.warn("Missing entity definition", stacktrace)

  #     true ->
  #       IO.warn("Expected the entity to be an atom got " <> inspect(entity), stacktrace)
  #   end
  # end

  def caller_stacktrace(%Macro.Env{
        module: module,
        function: {func, arity},
        file: file,
        line: line
      }) do
    [{module, func, arity, [file: to_charlist(file), line: line]}]
  end

  def caller_stacktrace(%Macro.Env{
        module: module,
        function: nil,
        file: file,
        line: line
      }) do
    [{module, :__MODULE__, 1, [file: to_charlist(file), line: line]}]
  end
end
