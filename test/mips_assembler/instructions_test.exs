# defmodule InstructionTest do
#   use ExUnit.Case
#   doctest MipsAssembler.Instruction
#
#   import MipsAssembler.Instruction, only: [new: 1]
#
#   describe "create an instruction" do
#     setup do
#       [
#         ok_data_r: %{op: "add", rd: "$t0", rs: "$zero", rt: "$t1", form: :r},
#         ok_data_i: %{op: "addi", rd: "$t0", rs: "$zero", immd: "1", form: :i},
#         ok_data_j: %{op: "j", address: "foo", form: :j},
#         ok_data_r_expected: %MipsAssembler.Instruction{
#           address: "",
#           form: :r,
#           immd: "",
#           offset: "",
#           op: "add",
#           rd: "$t0",
#           rs: "$zero",
#           rt: "$t1",
#           shamt: ""
#         },
#         ok_data_i_expected: %MipsAssembler.Instruction{
#           address: "",
#           form: :i,
#           immd: "1",
#           offset: "",
#           op: "addi",
#           rd: "$t0",
#           rs: "$zero",
#           rt: "",
#           shamt: ""
#         },
#         ok_data_j_expected: %MipsAssembler.Instruction{
#           address: "foo",
#           form: :j,
#           immd: "",
#           offset: "",
#           op: "j",
#           rd: "",
#           rs: "",
#           rt: "",
#           shamt: ""
#         },
#         error_data: %{rd: "$t0", rs: "$zero", rt: "$t1", form: :r}
#       ]
#     end
#
#     test "Success", fixture do
#       assert new(fixture.ok_data_r) == fixture.ok_data_r_expected
#       assert new(fixture.ok_data_i) == fixture.ok_data_i_expected
#       assert new(fixture.ok_data_j) == fixture.ok_data_j_expected
#     end
#
#     test "Failure", fixture do
#       assert_raise(FunctionClauseError, fn -> new(fixture.error_data) end)
#     end
#   end
#
#   #   import MipsAssembler.CLI, only: [parse_args: 1]
#   #
#   #   test ":help returned by option parsing with -h and --help options" do
#   #     assert parse_args(["-h", "anything"]) == :help
#   #     assert parse_args(["--help", "anything"]) == :help
#   #   end
#
#   #   test "three values returned if three given" do
#   #     assert parse_args(["user", "project", "99"]) == {"user", "project", 99}
#   #   end
#   #
#   #   test "count is defaulted if two values given" do
#   #     assert parse_args(["user", "project"]) == {"user", "project", 4}
#   #   end
# end
