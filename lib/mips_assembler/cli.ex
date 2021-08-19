defmodule MipsAssembler.CLI do
  @input_extention ".s"
  @output_extention ".txt"

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
    OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])
    |> _parse_args()
  end

  defp _parse_args({[help: true], _, _}), do: :help
  defp _parse_args({_, [file_name], _}), do: file_name
  defp _parse_args(_), do: :help

  def process(:help) do
    IO.puts("""
      Usage: mips_assembler <.s file> [options]

      ## Options
        -h          Same as `--help`

        --help      Display available options
    """)

    System.halt(0)
  end

  def process(file_name) do
    file_name
    |> File.read!()
    |> MipsAssembler.assemble()
    |> Kernel.then(fn binary ->
      output =
        Path.dirname(file_name) <>
          "/" <> Path.basename(file_name, @input_extention) <> @output_extention

      File.write(output, binary)
    end)
  end
end
