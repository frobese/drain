defmodule Drain.Link do
  @moduledoc ~S"""
  Defines a Drain Link and its default behaviour.

  A target GenServer for `handle_cast(event)` has to be given, it's called when there are incoming packages.
  """

  use GenServer
  require Logger
  alias Drain.Protocol

  @handshake_timeout 5_000

  @doc """
  Handle a received Drain message.
  """
  @callback handle(msg :: Map.t) :: :ok | nil

  @optional_callbacks handle: 1

  defmodule State do
    @moduledoc false
    defstruct target: nil, connection: nil, handshake: false, data: <<>>
  end

  @default_args [name: __MODULE__, target: nil]
  def start_link(args \\ []) do
    args = Keyword.merge(@default_args, args)
    Logger.warn("Link Keyword.merge #{inspect args}")
    GenServer.start_link(__MODULE__, args, name: args[:name])
  end

  def init(args) do
    static_endpoint() # use as fallback?
    {host, port} = endpoint()

    retries = Application.get_env(:drain, :retries, 5)
    unless is_integer(retries), do: raise("The retries option must be an integer")

    Logger.info("Connection to #{inspect host}:#{port}")
    {:ok, %State{target: args[:target]}, {:continue, {:connect, retries}}}
  end

  @doc """
  Sends a protocol message to the connected server.
  """
  @spec send(struct()) :: :ok | {:error, String.t()}
  def send(%{} = message) do
    packet = message |> Protocol.encode()
    GenServer.call(__MODULE__, {:send, packet})
  end
  @spec send_to(struct(), atom) :: :ok | {:error, String.t()}
  def send_to(%{} = message, link) do
    packet = message |> Protocol.encode()
    GenServer.call(link, {:send, packet})
  end

  def stats() do
    GenServer.call(__MODULE__, :stats)
  end

  # Server impl

  def handle_continue({:connect, retries}, %State{} = state)
      when is_integer(retries) and retries > 0 do
    static_endpoint() # use as fallback?
    {host, port} = endpoint()

    case :gen_tcp.connect(host, port, [:binary, active: true]) do
      {:ok, socket} ->
        Logger.debug("Connection established")
        #conn = Connection.generate(socket)
        conn = socket
        Process.send_after(self(), :handshake_timeout, @handshake_timeout)
        Logger.debug(fn -> "Connection id: #{inspect conn}" end)
        invoke_callback({:connect, "connected to #{inspect conn}"}, state)
        {:noreply, %State{state | connection: conn}}

      {:error, reason} ->
        Logger.error("Drain TCP connection failed #{inspect reason}")
        :timer.sleep(1000)
        {:noreply, %State{state | connection: reason}, {:continue, {:connect, retries - 1}}}
    end
  end

  def handle_continue({:connect, _retries}, state) do
    {:stop, state.connection, state}
  end

  # Processes the incoming TCP-Packets
  def handle_info({:tcp, _socket, packet}, state) do
    state.connection
    |> Protocol.decode(state.data <> packet)  # this should loop until :error
    |> case do
      {conn, {:ok, msg, rest}} ->
        # Some special cases...
        state = case msg do
          %Protocol.Hello{} = hello ->
            Logger.debug("Got hello from #{hello.ver}")

            packet = %Protocol.Info{} |> Protocol.encode()
            :ok = :gen_tcp.send(state.connection, packet)

            %State{state | handshake: true, data: rest}

          %Protocol.Ping{} ->
            Logger.debug("Got ping, sending pong")

            packet = %Protocol.Pong{} |> Protocol.encode()
            :ok = :gen_tcp.send(state.connection, packet)

            %State{state | data: rest}

          %{} = msg ->
            Logger.debug("Got msg #{inspect msg}")

            %State{state | data: rest}

          :error ->
            Logger.error("This can't happen...")
            %State{state | data: rest}
        end

        invoke_callback({:recv, msg}, state)
        {:noreply, %State{state | connection: conn}}

      {conn, {:error, packet}} ->
        {:noreply, %State{state | connection: conn, data: packet}}
    end
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.error("Connection failure: #{inspect reason}")
    {:stop, :tcp_error, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.warn("TCP connection closed")
    {:stop, :tcp_closed, state}
  end

  def handle_info(:handshake_timeout, %State{handshake: false} = state) do
    Logger.error("CBOR handshake timeout.")
    {:stop, :handshake_timeout, state}
  end

  def handle_info(:handshake_timeout, state) do
    {:noreply, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, state.connection.stats, state}
  end

  # adds compression if enabled, adds framing
  def handle_call({:send, packet}, _from, state)
      when is_binary(packet) do

    result = :gen_tcp.send(state.connection, packet)

    {:reply, result, state}
  end

  # Helper (event callback)

  defp invoke_callback(data, %State{target: nil}) do
    Logger.debug("Link got #{inspect data}")
  end
  defp invoke_callback(data, %State{target: target}) when is_atom(target) do
    GenServer.cast(target, data)
  end

  # Helper (config)

  defp endpoint do
    {:ok, hostport} = Drain.Discover.discover()
    hostport
  end

  defp static_endpoint do
    port = Application.get_env(:drain, :port, 6986)

    host =
      Application.get_env(:drain, :host, "localhost")
      |> String.to_charlist()

    {host, port}
  end
end
