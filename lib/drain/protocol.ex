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

  defmodule Info do
    @moduledoc false
    defstruct [] # these will change to a proper struct in v1
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
    defstruct [] # these will change to a proper struct in v1
  end

  defmodule Ping do
    @moduledoc false
    defstruct [] # these will change to a proper struct in v1
  end

  defmodule Pong do
    @moduledoc false
    defstruct [] # these will change to a proper struct in v1
  end

  def encode(msg) do
    data = msg
      |> case do
          # special cases, will change to a proper struct in v1
          %Info{} -> "Info"
          %Quit{} -> "Quit"
          %Ping{} -> "Ping"
          %Pong{} -> "Pong"
          %{__struct__: struct} = params -> %{modulename_to_key(struct) => Map.from_struct(params)}
      end
      |> CBOR.encode()

    # add framing
    << byte_size(data) :: size(32), data :: binary >>
  end

  # hacky stub for now, strips framing
  def decode(<< length :: size(32), data :: binary - size(length), rest :: binary >>) do
    {:ok, msg, ""} = CBOR.decode(data)
    Logger.debug("Packet raw (#{length} bytes): #{inspect msg}")
    msg = msg
      |> keys_to_atoms()
      |> case do
          %{:"Ok" => params} -> struct(Ok, params)
          %{:"Err" => params} -> struct(Err, params)
          %{:"Hello" => params} -> struct(Hello, params)
          "Info" -> %Info{}
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
          "Quit" -> %Quit{}
          "Ping" -> %Ping{}
          "Pong" -> %Pong{}
      end

    Logger.debug("Packet msg (#{length} bytes): #{inspect msg}")
    {:ok, msg, rest}
  end
  def decode(<<>>) do
    {:error, <<>>}
  end
  def decode(<< length :: size(32), _data :: binary >> = packet) do
    Logger.warn("Incomplete packet #{byte_size(packet)} of #{length} bytes")
    {:error, packet}
  end
  def decode(packet) when is_binary(packet) do
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
