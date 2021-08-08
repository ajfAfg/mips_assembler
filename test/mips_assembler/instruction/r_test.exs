defmodule RTest do
  use ExUnit.Case
  doctest MipsAssembler.Instruction.R

  alias MipsAssembler.Instruction.R

  describe "return a struct representing the R instruction" do
    setup do
      [
        add: %{op: "add", rd: "$t0", rs: "$zero", rt: "$t1"},
        add_expected: %R{
          op: "add",
          rd: "$t0",
          rs: "$zero",
          rt: "$t1",
          shamt: ""
        },
        mult: %{op: "mult", rt: "$t0", rs: "$t1"},
        mult_expected: %R{
          op: "mult",
          rd: "",
          rs: "$t1",
          rt: "$t0",
          shamt: ""
        },
        sll: %{op: "sll", rd: "$t0", rt: "$t1", shamt: "4"},
        sll_expected: %R{
          op: "sll",
          rd: "$t0",
          rs: "",
          rt: "$t1",
          shamt: "4"
        },
        mfhi: %{op: "mfhi", rd: "$t0"},
        mfhi_expected: %R{
          op: "mfhi",
          rd: "$t0",
          rs: "",
          rt: "",
          shamt: ""
        },
        jr: %{op: "jr", rs: "$t0"},
        jr_expected: %R{
          op: "jr",
          rd: "",
          rs: "$t0",
          rt: "",
          shamt: ""
        },
        jalr: %{op: "jalr", rs: "$t0", rd: "$t1"},
        jalr_expected: %R{
          op: "jalr",
          rd: "$t1",
          rs: "$t0",
          rt: "",
          shamt: ""
        }
      ]
    end

    test "add $t0, $zero, $t1", fixture do
      assert R.new(fixture.add) == fixture.add_expected
    end

    test "mult $t0, $t1", fixture do
      assert R.new(fixture.mult) == fixture.mult_expected
    end

    test "sll $t0, $t1, 4", fixture do
      assert R.new(fixture.sll) == fixture.sll_expected
    end

    test "mfhi $t0", fixture do
      assert R.new(fixture.mfhi) == fixture.mfhi_expected
    end

    test "jr $t0", fixture do
      assert R.new(fixture.jr) == fixture.jr_expected
    end

    test "jalr $t0, $t1", fixture do
      assert R.new(fixture.jalr) == fixture.jalr_expected
    end
  end

  describe "raise if op is not exist" do
    setup do
      [
        error: %{rd: "$t0", rs: "$zero", rt: "$t1"}
      ]
    end

    test "$t0, $zero, $t1  # op add is not existed", fixture do
      assert_raise(FunctionClauseError, fn -> R.new(fixture.error) end)
    end
  end
end
