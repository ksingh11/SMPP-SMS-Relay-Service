defmodule SmsServerTest do
  use ExUnit.Case
  doctest SmsServer

  test "greets the world" do
    assert SmsServer.hello() == :world
  end
end
