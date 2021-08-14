defmodule CliTest do
  use ExUnit.Case
  doctest MipsAssembler

  import MipsAssembler.CLI, only: [parse_args: 1, process: 1]

  test ":help returned by option parsing with -h and --help options" do
    assert parse_args(["-h", "anything"]) == :help
    assert parse_args(["--help", "anything"]) == :help
  end

  test "assemble" do
    process("test/test_program/foo.s")

    assert File.read!("test/test_program/foo.txt") === """
           00000001001010100100000000100000
           00001000000000000000000000000001
           """

    process("test/test_program/load_and_store.s")

    assert File.read!("test/test_program/load_and_store.txt") === """
           00100000000010000000000000000001
           00100000000010010000000000000010
           10101100000010000000000000000000
           10101100000010010000000000000100
           00000000000000001011100000100000
           10001110111100000000000000000000
           10001110111100010000000000000100
           00100010111010000000000000001000
           10101101000100010000000000000000
           00001000000000000000000000001001
           """
  end

  #   test "three values returned if three given" do
  #     assert parse_args(["user", "project", "99"]) == {"user", "project", 99}
  #   end
  #
  #   test "count is defaulted if two values given" do
  #     assert parse_args(["user", "project"]) == {"user", "project", 4}
  #   end
end
