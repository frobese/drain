defmodule Chat.Repo do
  use Drain.Repo,
    otp_app: :chat

  require Logger

  @impl true
  def drain_connect(msg) do
    Logger.info("chat federation connected #{inspect msg}")
    subscribe("chat/#") # note: we are in GenSever here
  end

#  @impl true
#  def drain_disconnect(msg) do
#    Logger.info("chat federation disconnected #{inspect msg}")
#  end

  @impl true
  def drain_info(msg) do
    Logger.info("chat federation info #{inspect msg}")
  end

  @impl true
  def drain_event(topic, json) do
    msg = json |> Jason.decode!()
    Logger.info("chat federation event #{inspect topic} -> #{inspect msg}")

    # You can use MyApp.Endpoint.broadcast(topic, event, msg) for that.
    # Check http://hexdocs.pm/phoenix/Phoenix.Endpoint.html
    ChatWeb.Endpoint.broadcast("room:lobby", "shout", msg)
  end

  def publish_json(payload, topic) do
    payload
    |> Jason.encode!()
    |> publish(topic)
  end
end
