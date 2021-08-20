defmodule MipsAssembler.CLI do
  @output_extension "txt"
  @output_dir "."

  @moduledoc """
  Handle the command line parsing and the dispatch to
  the various functions that end up generating a
  table of the last _n_ issues in a github project
  """

  def main(argv) do
    argv
    |> parse_args()
    |> process()
  end

  @doc """
  `argv` can be -h or --help, which returns :help.

  Otherwise it is a file name of MIPS code.
  """
  def parse_args(argv) do
    argv
    |> parse_option()
    |> args_to_internal_representation()
  end

  defp parse_option(argv) do
    {parsed, argv, errors} =
      OptionParser.parse(argv, aliases: [h: :help], strict: [output_dir: :string, help: :boolean])

    {Map.new(parsed), argv, errors}
  end

  defp args_to_internal_representation({%{help: true}, _, _}), do: :help

  defp args_to_internal_representation({%{output_dir: output_dir}, [file_name], _}),
    do: {file_name, output_dir}

  defp args_to_internal_representation({_, [file_name], _}), do: {file_name, @output_dir}
  defp args_to_internal_representation(_), do: :help

  def process(:help) do
    IO.puts("""
      Usage: mips_assembler <.s file> [options]

      ## Options
        -h              Same as `--help`

        --help          Display available options
        --output-dir    Specify output directory
    """)

    System.halt(0)
  end

  def process({file_name, output_dir}) do
    file_name
    |> File.read!()
    |> MipsAssembler.assemble()
    |> Kernel.then(fn binary ->
      generate_output_file_name(file_name, @output_extension, output_dir)
      |> File.write(binary)
    end)
  end

  def generate_output_file_name(file_name, output_extension, output_dir) do
    basename = file_name |> Path.extname() |> Kernel.then(&Path.basename(file_name, &1))
    output_dir <> "/" <> basename <> "." <> output_extension
  end
end
