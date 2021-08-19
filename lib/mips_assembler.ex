defmodule MipsAssembler do
  @moduledoc """
  Documentation for `MipsAssembler`.
  """

  def assemble(string) do
    string
    |> parse_assembly()
    |> convert_into_intermediate_representation()
    |> generate_binary_code()
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
