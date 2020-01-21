defmodule Drain.Store.Mnesia do
  @moduledoc false

  use Drain.Store
  require Logger

  def get(timestamp, modules, tags) do
    match_spec = {:drain, :"$1", :"$2", :"$3", :"$4"}

    guards =
      []
      |> timestamp_guard(timestamp)
      |> module_guard(modules)
      |> tag_guard(tags)

    :mnesia.transaction(fn ->
      :mnesia.select(:drain, [{match_spec, guards, [:"$$"]}])
    end)
    |> case do
      {:atomic, list} ->
        Enum.map(list, &List.to_tuple/1)

      _ ->
        []
    end

    # |> Stream.map(fn x -> load(x) end)
  end

  # TODO: Append-only should be ensured
  # TODO: Well-behaved
  def append({timestamp, module, tag, event}) do
    result =
      :mnesia.transaction(fn ->
        # :mnesia.match_object(
        #   {:drain, :_, :create, event.module, :_, event.entity_type, event.entity_uuid, :_, :_, :_}
        # )
        # |> case do
        #   [] ->
        {:drain, timestamp, module, tag, event}
        |> :mnesia.write()

        #   _ ->
        #     :noop
        # end
      end)

    case result do
      {:atomic, :ok} -> :ok
      _ -> :error
    end
  end

  defp timestamp_guard(guards, nil) do
    guards
  end

  defp timestamp_guard(guards, timestamp) do
    [{:>=, :"$1", timestamp} | guards]
  end

  defp module_guard(guards, nil) do
    guards
  end

  defp module_guard(guards, []) do
    guards
  end

  defp module_guard(guards, [module | modules]) do
    module_guard([{:==, :"$2", module} | guards], modules)
  end

  defp tag_guard(guards, nil) do
    guards
  end

  defp tag_guard(guards, []) do
    guards
  end

  defp tag_guard(guards, [tag | tags]) do
    tag_guard([{:==, :"$3", tag} | guards], tags)
  end

  # def append(%Drain.Event{} = event) do
  #   :mnesia.transaction(fn ->
  #     {:drain, event.timestamp, event.type, event.module, event.version, event.entity_type,
  #      event.entity_uuid, encode(event.data), event.application, event.host}
  #     |> :mnesia.write()
  #   end)

  #   # TODO: rethink
  #   {:ok, event}
  # end

  # def delete_all() do
  #   :mnesia.clear_table(:drain)
  # end

  def setup do
    # :mnesia.stop()

    with :ok <- init_schema(),
         :ok <- :mnesia.start(),
         :ok <-
           create_table(
             :drain,
             [
               :timestamp,
               :tag,
               :module,
               #  :version,
               #  :entity_type,
               #  :entity_uuid,
               #  :entity_id,
               :data
               #  :application,
               #  :host
             ],
             :ordered_set
           ) do
      #  :ok <- create_indices(:drain, :timestamp) do
      #  :ok <- create_indices(:drain, :module) do
      #  :ok <- create_indices(:drain, :entity_type),
      #  :ok <- create_indices(:drain, :entity_id),
      Logger.debug(inspect(:mnesia.system_info(:all), pretty: true))

      :ok
    else
      error ->
        Logger.error(inspect(error))
        :error
    end
  end

  defp init_schema do
    case :mnesia.create_schema([node()]) do
      :ok -> :ok
      {:error, {_, {:already_exists, _}}} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_indices(name, attribute) do
    case :mnesia.add_table_index(name, attribute) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, _name}} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp create_table(name, attributes, type \\ :set) do
    case :mnesia.create_table(name, attributes: attributes, type: type, disc_copies: [node()]) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, _name}} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end
end
