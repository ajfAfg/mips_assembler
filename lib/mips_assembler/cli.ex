defmodule MipsAssembler.CLI do
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

    # |> IO.inspect()
    # |> elem(1)
    # |> args_to_internal_representation()
  end

  def process(:help) do
    IO.puts("""
      usage: issues <file name>
    """)

    System.halt(0)
  end

  def process(file_name) do
    file_name
    |> File.read()

    # Issues.GithubIssues.fetch(user, project)
    # |> decode_response()
    # |> sort_into_descending_order()
    # |> last(count)
    # |> print_table_for_columns(["number", "created_at", "title"])
  end

  def _parse_args({[help: true], _, _}), do: :help
  def _parse_args({_, [file_name], _}), do: file_name
  def _parse_args(_), do: :help
  #   def args_to_internal_representation([file_name]) do
  #     file_name
  #   end
  #
  #   # 不正な引数または--helpの場合
  #   def args_to_internal_representation(_) do
  #     :help
  #   end
end
