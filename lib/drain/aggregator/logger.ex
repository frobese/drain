defmodule Drain.Aggregator.Logger do
  @moduledoc false

  use Drain.Aggregator
  require Logger

  def aggregate(event) do
    Logger.info(inspect(event, pretty: true))
  end
end
