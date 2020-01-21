defmodule Drain.EventTest do
  use ExUnit.Case

  alias Drain.Event

  doctest Drain.Event

  test "decode test" do
    event =
      %Event{
        module: SomeEvent,
        version: 1,
        data: %{data: "data"},
        host: node()
      }
      |> Drain.Gateway.finalize_event()

    encoded = Event.encode(event)

    assert {_timestamp, "Elixir.SomeEvent", <<_::binary>>} = encoded

    assert {:ok, event} == Event.decode(encoded)
  end

  test "decode error test" do
    event =
      %Event{
        module: SomeEvent,
        version: 1,
        data: %{data: "data"},
        host: node()
      }
      |> Drain.Gateway.finalize_event()

    {timestamp, mod_string, encoded} = Event.encode(event)

    assert {:error, :integrity_error} = Event.decode({1234, mod_string, encoded})
    assert {:error, :integrity_error} = Event.decode({timestamp, "NotAModule", encoded})

    assert {:error, :integrity_error} =
             Event.decode({timestamp, mod_string, Base.encode64("WierdStuff")})
  end
end
