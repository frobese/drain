defmodule Drain.Utils do
  alias Drain.Event

  def encode_event(%Event{} = event) do
    {event.timestamp, Atom.to_string(event.module), event.tag,
     Base.encode64(:erlang.term_to_binary(event))}
  end

  def decode_event({timestamp, module_string, tag, encoded_event}) do
    with module <- String.to_existing_atom(module_string),
         {:ok, binary_event} <- Base.decode64(encoded_event),
         %Event{timestamp: ^timestamp, module: ^module, tag: ^tag} = event <-
           :erlang.binary_to_term(binary_event, [:safe]) do
      {:ok, event}
    else
      %Event{} ->
        {:error, :integrity_error}

      :error ->
        {:error, :encoding_error}
    end
  rescue
    ArgumentError ->
      {:error, :integrity_error}
  end
end
