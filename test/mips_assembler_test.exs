defmodule MipsAssemblerTest do
  use ExUnit.Case
  doctest MipsAssembler

  test "greets the world" do
    assert MipsAssembler.hello() == :world
  end
end
