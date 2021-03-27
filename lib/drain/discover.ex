defmodule Drain.Discover do
  @moduledoc ~S"""
  Discover Drain servers.
  """

  require Logger

  @broadcast_port 5670
  @broadcast_addr {255,255,255,255}
  @timeout 1500

  @doc """
  Discover Drain servers once.
  """
  def discover(group \\ "default") do
    with {:ok, socket} <- :gen_udp.open(0, [:binary, {:active, false}, {:broadcast, true}]),
         :ok <- :gen_udp.send(socket, @broadcast_addr, @broadcast_port, locator(group)),
         {:ok, {addr, _bport, beacon}} <- :gen_udp.recv(socket, 0, @timeout),
         {:ok, {_group, _uuid, sport}} <- parse_beacon(beacon)
    do
      {:ok, {addr, sport}}
    else
      {:error, reason} = err ->
        Logger.warn("Locator beacon failed: #{inspect reason}")
        err
    end
  end

  def locator(group \\ "default") do
    <<
      "DRA", 1,
      format_group(group)::binary,
      0::128, # Uuid nil
      0::16, # port 0
    >>
  end

  def parse_beacon(<<
    "DRA", 1,
    group::binary-size(8),
    uuid::binary-size(16),
    port::16,
  >>) do
    {:ok, {group, uuid, port}}
  end
  def parse_beacon(_) do
    {:error, "Can't parse beacon"}
  end

  def format_group(group \\ "default") do
    group
    |> to_string()
    |> String.pad_trailing(8, "_")
    |> String.slice(0, 8)
  end
end
