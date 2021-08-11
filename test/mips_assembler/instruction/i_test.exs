defmodule ITest do
  use ExUnit.Case
  doctest MipsAssembler.Instruction.I

  alias MipsAssembler.Instruction.I

  describe "return a struct representing the I instruction" do
    setup do
      [
        addi: %{op: "addi", rt: "$t0", rs: "$zero", immd: "1"},
        addi_expected: %I{
          op: "addi",
          rt: "$t0",
          rs: "$zero",
          immd: "1"
        },
        bgez: %{op: "bgez", rs: "$t0", immd: "foo"},
        bgez_expected: %I{
          op: "bgez",
          rt: nil,
          rs: "$t0",
          immd: "foo"
        },
        lw: %{op: "lw", rt: "$t0", rs: "$t1", immd: "12"},
        lw_expected: %I{
          op: "lw",
          rt: "$t0",
          rs: "$t1",
          immd: "12"
        }
      ]
    end

    test "addi $t0, $zero, 1", fixture do
      assert I.new(fixture.addi) == fixture.addi_expected
    end

    test "bgez $t0, foo", fixture do
      assert I.new(fixture.bgez) == fixture.bgez_expected
    end

    test "lw $t0, 12($t1)", fixture do
      assert I.new(fixture.lw) == fixture.lw_expected
    end
  end

  describe "raise if op is not exist" do
    setup do
      [
        error: %{rt: "$t0", rs: "$zero", immd: "1"}
      ]
    end

    test "$t0, $zero, 1  # op addi is not existed", fixture do
      assert_raise(FunctionClauseError, fn -> I.new(fixture.error) end)
    end
  end
end
