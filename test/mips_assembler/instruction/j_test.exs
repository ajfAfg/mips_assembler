defmodule JTest do
  use ExUnit.Case
  doctest MipsAssembler.Instruction.J

  alias MipsAssembler.Instruction.J

  describe "return a struct representing the J instruction" do
    setup do
      [
        j: %{op: "j", address: "foo"},
        j_expected: %J{
          op: "j",
          address: "foo"
        }
      ]
    end

    test "j foo", fixture do
      assert J.new(fixture.j) == fixture.j_expected
    end
  end

  describe "raise if op is not exist" do
    setup do
      [
        error: %{address: "foo"}
      ]
    end

    test "foo  # op j is not existed", fixture do
      assert_raise(FunctionClauseError, fn -> J.new(fixture.error) end)
    end
  end
end
