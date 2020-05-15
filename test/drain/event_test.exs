defmodule Drain.EventTest do
  use ExUnit.Case

  alias Drain.{Event, Utils}

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

    encoded = Utils.encode_event(event)

    assert {_timestamp, "Elixir.SomeEvent", nil, <<_::binary>>} = encoded

    assert {:ok, event} == Utils.decode_event(encoded)
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

    {timestamp, mod_string, nil, encoded} = Utils.encode_event(event)

    assert {:error, :integrity_error} = Utils.decode_event({1234, mod_string, nil, encoded})

    assert {:error, :integrity_error} =
             Utils.decode_event({timestamp, "NotAModule", nil, encoded})

    assert {:error, :integrity_error} =
             Utils.decode_event({timestamp, mod_string, nil, Base.encode64("WierdStuff")})
  end
end
