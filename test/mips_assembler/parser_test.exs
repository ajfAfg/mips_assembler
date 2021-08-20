defmodule ParserTest do
  use ExUnit.Case, async: true
  doctest MipsAssembler.Parser

  #   alias MipsAssembler.Instruction.R
  #   alias MipsAssembler.Instruction.I
  #   alias MipsAssembler.Instruction.J
  #
  #   import MipsAssembler.Parser, only: [parse: 1, parse_label: 3, parse_op: 3, parse_other: 4]
  #
  #   describe "add an instruction into the old instruction list" do
  #     test "'op rd, rs, rt' family" do
  #       op = "add"
  #       expected = R.new(%{op: op, rd: "$t0", rs: "$t1", rt: "$t2"})
  #
  #       assert parse_other_helper("$t0, $t1, $t2", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1, $t2", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1, $t2\n", [], %{}, op) == expected
  #       assert parse_other_helper("\t $t0,  $t1,  $t2\n ", [], %{}, op) == expected
  #     end
  #
  #     test "'op rs, rt' family" do
  #       op = "mult"
  #       expected = R.new(%{op: op, rs: "$t0", rt: "$t1"})
  #
  #       assert parse_other_helper("$t0, $t1", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1\n", [], %{}, op) == expected
  #       assert parse_other_helper("\t $t0,  $t1\n ", [], %{}, op) == expected
  #     end
  #
  #     test "'op rd, rt, shamt' family" do
  #       op = "sll"
  #       expected = R.new(%{op: op, rd: "$t0", rt: "$t1", shamt: "12"})
  #
  #       assert parse_other_helper("$t0, $t1, 12", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1, 12", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1, 12\n", [], %{}, op) == expected
  #       assert parse_other_helper("\t $t0,  $t1,  12\n ", [], %{}, op) == expected
  #     end
  #
  #     test "'op rd' family" do
  #       op = "mfhi"
  #       expected = R.new(%{op: op, rd: "$t0"})
  #
  #       assert parse_other_helper("$t0", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0\n", [], %{}, op) == expected
  #       assert parse_other_helper("\t $t0\n ", [], %{}, op) == expected
  #     end
  #
  #     test "'op rs' family" do
  #       op = "jr"
  #       expected = R.new(%{op: op, rs: "$t0"})
  #
  #       assert parse_other_helper("$t0", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0\n", [], %{}, op) == expected
  #       assert parse_other_helper("\t $t0\n ", [], %{}, op) == expected
  #     end
  #
  #     test "'op rs, rd' family" do
  #       op = "jalr"
  #       expected = R.new(%{op: op, rs: "$t0", rd: "$t1"})
  #
  #       assert parse_other_helper("$t0, $t1", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1\n", [], %{}, op) == expected
  #       assert parse_other_helper("\t $t0,  $t1\n ", [], %{}, op) == expected
  #     end
  #
  #     test "'op rt, rs, immd' family" do
  #       op = "addi"
  #       expected = I.new(%{op: op, rt: "$t0", rs: "$t1", immd: "12"})
  #
  #       assert parse_other_helper("$t0, $t1, 12", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1, 12", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, $t1, 12\n", [], %{}, op) == expected
  #       assert parse_other_helper("\t $t0,  $t1,  12\n ", [], %{}, op) == expected
  #     end
  #
  #     test "'op rs, offset' family" do
  #       op = "bgez"
  #       expected = I.new(%{op: op, rs: "$t0", immd: "12"})
  #
  #       assert parse_other_helper("$t0, 12", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, 12", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, 12\n", [], %{}, op) == expected
  #       assert parse_other_helper("\t $t0,  12\n ", [], %{}, op) == expected
  #     end
  #
  #     test "'op rt, offset(rs)' family" do
  #       op = "lw"
  #       expected = I.new(%{op: op, rt: "$t0", rs: "$t1", immd: "12"})
  #
  #       assert parse_other_helper("$t0, 12($t1)", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, 12($t1)", [], %{}, op) == expected
  #       assert parse_other_helper(" $t0, 12($t1)\n", [], %{}, op) == expected
  #       assert parse_other_helper("\n $t0,  12($t1)\n ", [], %{}, op) == expected
  #     end
  #   end
  #
  #   defp parse_other_helper(string, instructions, labels, op) do
  #     parse_other(string, instructions, labels, op)
  #     |> elem(0)
  #     |> List.first()
  #   end
end
