defmodule CliTest do
  use ExUnit.Case, async: true
  doctest MipsAssembler

  import MipsAssembler.CLI, only: [parse_args: 1, generate_output_file_name: 3]

  describe "Parse command line arguments" do
    test ":help returned by option parsing with -h and --help options" do
      assert parse_args(["-h", "anything"]) == :help
      assert parse_args(["--help", "anything"]) == :help
    end

    test "Return the file name and the output directory by option parsing with --output-dir" do
      assert parse_args(["--output-dir", "bar", "foo.s"]) === {"foo.s", "bar"}
    end

    test "-h and --help options take precedence over other options" do
      assert parse_args(["-h", "--output-dir", "bar", "foo.s"]) == :help
      assert parse_args(["--help", "--output-dir", "bar", "foo.s"]) == :help
    end

    test "Return the file name and the default output directory when an output directory is not specified" do
      assert parse_args(["foo.s"]) === {"foo.s", "."}
    end
  end

  describe "Generate a file name based on the base name of the input file name and the specified extension and directory." do
    test "Change the extension" do
      assert generate_output_file_name("./foo.s", "txt", ".") === "./foo.txt"
    end

    test "Add the directory name at the beginning of the file name" do
      assert generate_output_file_name("foo.s", "txt", "bar") === "bar/foo.txt"
    end

    test "Add the directory name at the beginning of the file name even if it is the current directory" do
      assert generate_output_file_name("foo.s", "txt", ".") === "./foo.txt"
    end
  end
end
