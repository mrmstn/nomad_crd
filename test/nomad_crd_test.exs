defmodule NomadCrdTest do
  use ExUnit.Case
  doctest NomadCrd

  test "greets the world" do
    assert NomadCrd.hello() == :world
  end
end
