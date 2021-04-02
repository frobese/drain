defmodule Drain.Server do
  @moduledoc ~S"""
  Spawns a Stormdrain server with some options.

  - bind_addr: "0.0.0.0:6986"
  - datadir: nil
  - readonly: false
  - snapshot: false
  """

  use GenServer
  require Logger
  alias Drain.Protocol

  @default_args [
    name: __MODULE__,
    exe: nil,
    bind_addr: "0.0.0.0:6986",
    datadir: nil,
    readonly: false,
    snapshot: false,
  ]
  def start_link(args \\ []) do
    args = Keyword.merge(@default_args, args)
    Logger.debug("Server args #{inspect args}")
    GenServer.start_link(__MODULE__, args, name: args[:name])
  end

  def init(args) do
    Process.flag(:trap_exit, true)
    exe = args[:exe] || get_exe()
    bind_addr = if args[:bind_addr], do: ["-a", args[:bind_addr]], else: []
    readonly = if args[:readonly], do: "--readonly", else: []
    snapshot = if args[:snapshot], do: "--snapshot", else: []
    datadir = if args[:datadir], do: args[:datadir], else: []
    params = [bind_addr, "serve", "--pipe", readonly, snapshot, datadir] |> List.flatten()
    Logger.info("Launching server #{exe} with #{inspect params}")
    port = Port.open({:spawn_executable, exe}, [:binary, {:packet, 4}, args: params])
    Logger.debug("Port #{inspect Port.info(port)}")
    Port.monitor(port)
    {:ok, port}
  end

  # this won't work on Ctrl-C...
  def terminate(reason, _state) do
    Logger.debug("Drain server terminate #{inspect reason}")
  end

  def handle_info({:DOWN, ref, :port, object, reason}, state) do
    Logger.error("Drain server down: ref is #{inspect ref} object: #{inspect object} reason: #{inspect reason} state was #{inspect state}")
    # try to restart...?
    {:stop, :error, nil}
  end

  # data sent by the port
  def handle_info({_port, {:data, data}}, state) do
    case Protocol.decode(data) do
      {:ok, msg, _rest} ->
        # Some special cases...
        case msg do
          %Protocol.Hello{} = hello ->
            Logger.debug("Got hello from #{hello.ver}")
            # packet = %Protocol.Hello{} |> Protocol.encode()
            # send(state, {self(), {:command, packet}})
            # %State{state | handshake: true} # maybe later...

          %Protocol.Ping{} ->
            Logger.debug("Got ping, sending pong")
            packet = %Protocol.Pong{} |> Protocol.encode()
            send(state, {self(), {:command, packet}})

          %{} = msg ->
            Logger.debug("Got msg #{inspect msg}")
        end

        # invoke_callback({:recv, msg}, state)
        {:noreply, state}

      {:error, reason} ->
        Logger.warn("Server frame error #{inspect reason}")
        {:noreply, state}
    end
  end
  # reply to the {pid, :close} message
  def handle_info({_port, :closed}, state) do
    Logger.warn("Drain server CLOSED")
    {:noreply, state}
  end

  # exit signals in case the port crashes, this won't work on Ctrl-C...
  def handle_info({:EXIT, _port, reason}, state) do
    Logger.warn("Drain server EXIT #{reason}")
    {:noreply, state}
  end

  @doc """
  Returns the architecture the system runs on.

  E.g. "x86_64-pc-linux-gnu", "x86_64-apple-darwin18.7.0", "i686-pc-linux-gnu"
  """
  @spec architecture() :: String.t()
  def architecture do
    :erlang.system_info(:system_architecture) |> to_string()
  end

  @doc """
  Returns the architecture the system was compiled with.

  E.g. "x86_64-pc-linux-gnu", "x86_64-apple-darwin18.7.0", "i686-pc-linux-gnu"
  """
  @architecture :erlang.system_info(:system_architecture) |> to_string()
  @spec compile_architecture() :: String.t()
  def compile_architecture do
    @architecture
  end

  def get_exe(), do:
    get_exe(architecture())
  # we should resolve more architectures...
  def get_exe("x86_64-pc-linux" <> _), do:
    Path.join(:code.priv_dir(:drain), "stormdrain-x86_64-unknown-linux-gnu")
  def get_exe("x86_64-apple-darwin" <> _), do:
    Path.join(:code.priv_dir(:drain), "stormdrain-x86_64-apple-darwin")
  # else fail

  # defp kill(port) do
  #   {:os_pid, os_pid} = Port.info(port, :os_pid)
  #   true = Port.close(port)
  #   # Kill the port forcibly
  #   Logger.debug("Killing pid #{os_pid}")
  #   System.cmd("kill", [to_string(os_pid)])
  #   # System.cmd("kill", ["-9", to_string(os_pid)])
  # end
end
