defmodule Drain.Watcher do
  @moduledoc false
  use GenServer

  @doc false
  def start_link(tuple) do
    GenServer.start_link(__MODULE__, tuple)
  end

  @impl true
  def init({handler, args}) do
    Process.flag(:trap_exit, true)

    case :gen_event.delete_handler(Drain, handler, :ok) do
      {:error, :module_not_found} ->
        case :gen_event.add_sup_handler(Drain, handler, args) do
          :ok ->
            {:ok, handler}

          {:error, :ignore} ->
            # Can't return :ignore as a transient child under a one_for_one.
            # Instead return ok and then immediately exit normally - using a fake
            # message.
            send(self(), {:gen_event_EXIT, handler, :normal})
            {:ok, handler}

          {:error, reason} ->
            {:stop, reason}

          {:EXIT, _} = exit ->
            {:stop, exit}
        end

      _ ->
        init({handler, args})
    end
  end

  @impl true
  def handle_info({:gen_event_EXIT, handler, reason}, handler)
      when reason in [:normal, :shutdown] do
    {:stop, reason, handler}
  end

  def handle_info({:gen_event_EXIT, handler, reason}, handler) do
    if not processor_has_backends?() do
      IO.puts(:stderr, [
        ":gen_event handler ",
        inspect(handler),
        " installed in Drain terminating\n",
        "** (exit) ",
        format_exit(reason)
      ])
    end

    {:stop, reason, handler}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp processor_has_backends? do
    :gen_event.which_handlers(Drain) != []
  rescue
    _ -> false
  end

  @impl true
  def terminate(_reason, handler) do
    # On terminate we remove the handler, this makes the
    # process sync, allowing existing messages to be flushed
    :gen_event.delete_handler(Drain, handler, :ok)
    :ok
  end

  defp format_exit({:EXIT, reason}), do: Exception.format_exit(reason)
  defp format_exit(reason), do: Exception.format_exit(reason)
end
