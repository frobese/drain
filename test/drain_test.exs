defmodule DrainTest do
  use ExUnit.Case
  doctest Drain

  test "greets the world" do
    assert Drain.hello() == :world
  end
end
