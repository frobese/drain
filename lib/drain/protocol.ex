defmodule Drain.Protocol do
  require Logger

  defmodule Ok do
    @moduledoc false
    defstruct msg: nil
  end

  defmodule Err do
    @moduledoc false
    defstruct msg: nil
  end

  defmodule Hello do
    @moduledoc false
    defstruct ver: nil, state: nil, active: nil, passive: []
  end

  defmodule Pub do
    @moduledoc false
    defstruct qos: 0, topic: nil, payload: nil
  end

  defmodule Get do
    @moduledoc false
    defstruct sid: nil, seq: nil
  end

  defmodule ChkSub do
    @moduledoc false
    defstruct topic: nil, from: nil, recent: nil, limit: nil, unique: nil
  end

  defmodule ChkDup do
    @moduledoc false
    defstruct sid: nil, from: nil
  end

  defmodule List do
    @moduledoc false
    defstruct topic: nil, from: nil, recent: nil, limit: nil, unique: nil
  end

  defmodule Sub do
    @moduledoc false
    defstruct topic: nil, from: 0, recent: 0, limit: 0, unique: false
  end

  defmodule Dup do
    @moduledoc false
    defstruct sid: nil, from: nil
  end

  defmodule Unsub do
    @moduledoc false
    defstruct topic: nil
  end

  defmodule Undup do
    @moduledoc false
    defstruct sid: nil
  end

  defmodule Event do
    @moduledoc false
    defstruct event: nil
  end

  defmodule Quit do
    @moduledoc false
    defstruct [] # empty for now
  end

  defmodule Ping do
    @moduledoc false
    defstruct [] # empty for now
  end

  defmodule Pong do
    @moduledoc false
    defstruct [] # empty for now
  end

  # encodes without framing
  def encode(%{__struct__: struct} = params) do
    %{modulename_to_key(struct) => Map.from_struct(params)}
    |> CBOR.encode()
  end

  # encodes and adds framing
  def encode_framed(msg) do
    data = encode(msg)
    << byte_size(data) :: size(32), data :: binary >>
  end

  # decode a single packet without framing
  def decode(data) do
    case CBOR.decode(data) do
      {:ok, msg, <<>>} ->
        Logger.debug("Packet raw (#{byte_size(data)} bytes): #{inspect msg}")
        {:ok, decode_internal(msg), <<>>}

      {:ok, msg, rest} ->
        Logger.warn("CBOR decode short length, ignoring #{byte_size(rest)} of #{byte_size(data)} bytes")
        {:ok, decode_internal(msg), rest}

      {:error, err} ->
        {:error, err}
    end
  end

  # hacky stub for now
  def decode_internal(msg) do
    msg
    |> keys_to_atoms()
    |> case do
      %{:"Ok" => params} -> struct(Ok, params)
      %{:"Err" => params} -> struct(Err, params)
      %{:"Hello" => params} -> struct(Hello, params)
      %{:"Pub" => params} -> struct(Pub, params)
      %{:"Get" => params} -> struct(Get, params)
      %{:"ChkSub" => params} -> struct(ChkSub, params)
      %{:"ChkDup" => params} -> struct(ChkDup, params)
      %{:"List" => params} -> struct(List, params)
      %{:"Sub" => params} -> struct(Sub, params)
      %{:"Dup" => params} -> struct(Dup, params)
      %{:"Unsub" => params} -> struct(Unsub, params)
      %{:"Undup" => params} -> struct(Undup, params)
      %{:"Event" => params} -> struct(Event, params)
      %{:"Quit" => _params} -> %Quit{}
      %{:"Ping" => _params} -> %Ping{}
      %{:"Pong" => _params} -> %Pong{}
    end
  end

  # remove framing and decode
  def decode_framed(<< length :: size(32), data :: binary - size(length), rest :: binary >>) do
    case decode(data) do
      {:ok, msg, <<>>} ->
        {:ok, msg, rest}

      {:ok, msg, padding} ->
        Logger.warn("CBOR decode short length, ignoring #{byte_size(padding)} of #{length} bytes")
        {:ok, msg, rest}

      {:error, err} ->
        {:error, err}
    end
  end
  def decode_framed(<<>>) do
    {:error, <<>>}
  end
  def decode_framed(<< length :: size(32), _data :: binary >> = packet) do
    Logger.warn("Incomplete packet #{byte_size(packet)} of #{length} bytes")
    {:error, packet}
  end
  def decode_framed(packet) when is_binary(packet) do
    Logger.warn("Incomplete packet #{byte_size(packet)} bytes")
    {:error, packet}
  end

  defp modulename_to_key(name) do
    name |> Module.split() |> Elixir.List.last()
  end

  defp keys_to_atoms(struct) when is_struct(struct) do
    struct
  end
  defp keys_to_atoms(json) when is_map(json) do
    Map.new(json, &reduce_keys_to_atoms/1)
  end
  defp keys_to_atoms(other) do
    other
  end
  defp reduce_keys_to_atoms({key, %CBOR.Tag{tag: :bytes, value: bin}}), do: {String.to_atom(key), bin}
  defp reduce_keys_to_atoms({key, val}) when is_map(val), do: {String.to_atom(key), keys_to_atoms(val)}
  defp reduce_keys_to_atoms({key, val}) when is_list(val), do: {String.to_atom(key), Enum.map(val, &keys_to_atoms(&1))}
  defp reduce_keys_to_atoms({key, val}), do: {String.to_atom(key), val}
end
