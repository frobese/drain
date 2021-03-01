defmodule Drain.Repo do
  @moduledoc """
  Defines a Drain repository and its default behaviour.

  A repository handles the protocol and connect to some Drain server using a Link.

  When used, the repository expects the `:link` as option.
  The `:link` is a module name  of a link to use.
  For example, the repository:

      defmodule Repo do
        use Drain.Repo,
          link: Chat.Link
      end

  """

  @doc """
  The Drain link connected.
  """
  @callback drain_connect(msg :: String.t) :: :ok | nil

  @doc """
  The Drain link disconnected.
  """
  @callback drain_disconnect(msg :: String.t) :: :ok | nil

  @doc """
  The Drain link received some info.
  """
  @callback drain_info(msg :: String.t) :: :ok | nil

  @doc """
  The Drain link received an event.
  """
  @callback drain_event(topic :: String.t, msg :: String.t) :: :ok | nil

  @optional_callbacks drain_connect: 1,
                      drain_disconnect: 1,
                      drain_info: 1,
                      drain_event: 2

  @doc false
  defmacro __using__(opts) do
    link = Keyword.get(opts, :link, nil)
    quote bind_quoted: [link: link] do
      @behaviour Drain.Repo
      alias Drain.Protocol
      use GenServer
      require Logger

      alias __MODULE__
      defmodule Link do
        @moduledoc false
        def child_spec(init_arg) do
          Drain.Link.child_spec([{:name, __MODULE__}, {:target, Repo} | init_arg])
        end
      end

      # Client

      @link link || __MODULE__.Link
      @default_args [name: __MODULE__, link: @link]
      def start_link(args \\ []) do
        args = Keyword.merge(@default_args, args)
        Logger.warn("Keyword.merge #{inspect args}")
        GenServer.start_link(__MODULE__, args, name: args[:name])
      end

      # API

      @doc """
      Sends a publish to the connected server.
      """
      def publish(payload, topic) when is_binary(payload) do
        Logger.debug("publish #{inspect topic} -> #{inspect payload}")
        %Protocol.Pub{topic: topic, payload: payload}
        |> Drain.Link.send_to(@link)
      end

      @doc """
      Sends a subscribe to the connected server.
      """
      def subscribe(topic) do
        Logger.debug("subscribe #{inspect topic}")
        %Protocol.Sub{topic: topic}
        |> Drain.Link.send_to(@link)
      end

      @doc """
      Sends a unsubscribe to the connected server.
      """
      def unsubscribe(topic) do
        Logger.debug("unsubscribe #{inspect topic}")
        %Protocol.Unsub{topic: topic}
        |> Drain.Link.send_to(@link)
      end

      @doc """
      Gets all current subscriptions.
      """
      def subscriptions() do
        []
      end

      @doc """
      Sends a list to the connected server.
      """
      def list(topic, _bar) do
        Logger.debug("list #{inspect topic}")
        # %Protocol.List{topic: topic}
        # |> Drain.Link.send_to(@link)
        []
      end

      @doc """
      Sends a get to the connected server.
      """
      def get(topic, _bar) do
        Logger.debug("get #{inspect topic}")
        # %Protocol.Get{topic: topic}
        # |> Drain.Link.send_to(@link)
        nil
      end

      # Client default callbacks

      @doc false
      def drain_connect(msg) do
        Logger.debug("drain_connect #{inspect msg}")
      end
      @doc false
      def drain_disconnect(msg) do
        Logger.debug("drain_disconnect #{inspect msg}")
      end
      @doc false
      def drain_info(msg) do
        Logger.debug("drain_info #{inspect msg}")
      end
      @doc false
      def drain_event(topic, msg) do
        Logger.debug("drain_event #{inspect topic} -> #{inspect msg}")
      end

      defoverridable drain_connect: 1, drain_disconnect: 1, drain_info: 1, drain_event: 2

      # Server (callbacks)

      @impl true
      def init(init_arg) do
        {:ok, init_arg}
      end

      @impl true
      def handle_call(:pop, _from, [head | tail]) do
        {:reply, head, tail}
      end

      @impl true
      def handle_cast({:recv, %Protocol.Event{event: event}}, state) do
        # %Protocol.Event{event: %{payload: "Hello", seq: 1, time: %{}, topic: "chat"}}
        drain_event(event.topic, event.payload)
        {:noreply, state}
      end
      def handle_cast({:recv, msg}, state) do
        drain_info(msg)
        {:noreply, state}
      end
      def handle_cast({:connect, msg}, state) do
        drain_connect(msg)
        {:noreply, state}
      end
      def handle_cast({:disconnect, msg}, state) do
        drain_disconnect(msg)
        {:noreply, state}
      end
      def handle_cast({meta, msg}, state) do
        Logger.debug("Repo #{inspect meta } meta of #{inspect msg}")
        {:noreply, state}
      end

      defmodule Subscriptions do
        @moduledoc false
        defstruct [:types] # Repo state consists of all type tables
      end
    end
  end
end
