defmodule ErlmoneyTest do
  use ExUnit.Case
  doctest Erlmoney

  test "greets the world" do
    assert Erlmoney.hello() == :world
  end
end
