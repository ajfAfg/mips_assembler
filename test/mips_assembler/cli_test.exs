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

    process("test/test_program/array.s")

    assert File.read!("test/test_program/array.txt") === """
           00100000000100000000000000000010
           00000000000000001011100000100000
           00100000000010000000000000000000
           00100000000010010000000000000001
           00100000000010100000000000000010
           00100000000010110000000000000011
           00100000000011000000000000000100
           00100000000011010000000000000101
           10101110111010000000000000000000
           10101110111010010000000000000100
           10101110111010100000000000001000
           10101110111010110000000000001100
           10101110111011000000000000010000
           10101110111011010000000000010100
           00000000000100000100000010000000
           00000010111010000100000000100000
           10001101000100010000000000000000
           10001110111100100000000000010100
           00001000000000000000000000010010
           """

    process("test/test_program/while.s")

    assert File.read!("test/test_program/while.txt") === """
           00000000000000001000000000100000
           00000000000000001011100000100000
           00101010000010000000000000001010
           00010001000000000000000000000110
           00000000000100000100000010000000
           00000010111010000100000000100000
           10101101000100000000000000000000
           00100010000100000000000000000001
           00001000000000000000000000000010
           00001000000000000000000000001001
           """
  end
end
