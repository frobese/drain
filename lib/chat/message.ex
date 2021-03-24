defmodule Chat.Message do
  defstruct [:message, :name, :timestamp]

  @doc false
  def from_payload(message) do
    message
    # |> cast(attrs, [:name, :message])
    # |> validate_required([:name, :message])
  end

  def get_messages(limit \\ 20) do
    Chat.Repo.list("chat/message", limit: limit)
  end
end
