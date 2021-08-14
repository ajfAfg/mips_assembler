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
      usage: mips_assembler <file name>
    """)

    System.halt(0)
  end

  def process(file_name) do
    file_name
    |> File.read!()
    |> parse_assembly()
    |> convert_into_intermediate_representation()
    |> generate_binary_code()
    |> Kernel.then(fn binary ->
      output =
        Path.dirname(file_name) <>
          "/" <> Path.basename(file_name, @input_extention) <> @output_extention

      File.write(output, binary)
    end)
  end

  def parse_assembly(string) do
    string
    |> MipsAssembler.Parser.parse()
    |> check_no_error_for_statements()
  end

  defp check_no_error_for_statements(statements) do
    if Enum.all?(statements, fn {ok, _} -> ok === :ok end) do
      statements
    else
      statements
      |> Enum.filter(fn {error, _} -> error === :error end)
      |> Enum.each(fn {_error, {line_number, _element}} ->
        IO.puts("Syntax Error (#{line_number})")
      end)

      System.halt(1)
    end
  end

  def convert_into_intermediate_representation(statements) do
    statements
    |> MipsAssembler.Converter.convert()
    |> Kernel.then(fn {labels, instructions} ->
      {check_no_error_for_labels(labels), check_no_error_for_instructions(instructions)}
    end)
  end

  defp check_no_error_for_labels(labels) do
    labels
    |> Enum.to_list()
    |> Enum.filter(fn {_k, v} -> v === :error end)
    |> case do
      [] ->
        labels

      list ->
        Enum.each(list, fn {label, _v} -> IO.puts("Error: Duplicate the label #{label}.") end)
    end
  end

  defp check_no_error_for_instructions(instructions) do
    if Enum.all?(instructions, &(&1 !== :error)) do
      instructions
    else
      IO.puts("Fatal Error")
    end
  end

  def generate_binary_code({labels, instructions}) do
    MipsAssembler.Generator.generate_binary(instructions, labels)
    |> case do
      :error ->
        IO.puts("Fatal Error")
        System.halt(1)

      binary ->
        binary
    end
  end
end
