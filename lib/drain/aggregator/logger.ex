defmodule Drain.Processor.Logger do
  @moduledoc false

  use Drain.Processor
  require Logger

  @impl true
  def digest(event) do
    Logger.info(inspect(event, pretty: true))
  end
end
