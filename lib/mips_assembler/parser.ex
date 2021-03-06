defmodule MipsAssembler.Parser do
  @init_element %{label: "", instruction: {}}

  @moduledoc false

  import MipsAssembler.Either, only: [ok: 1, error: 1, chain: 2]

  def parse(string) do
    string
    |> init()
    |> parse_program()
    |> Enum.reverse()
  end

  def init(string) do
    %{
      string: remove_comment(string),
      statements: [],
      current: %{line_number: 0, element: @init_element}
    }
  end

  @doc ~S"""
  remove comment

  ## Example
      iex> import MipsAssembler.Parser, only: [remove_comment: 1]
      iex> remove_comment("aaa#bbb\n#\nccc")
      "aaa\n\nccc"
  """
  def remove_comment(string), do: String.replace(string, ~r{#.*}, "")

  @doc ~S"""
  program

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_program: 1]
      iex> program = "_start:\n    add\t$t0, $t1, $t2\nfoo:    j    foo"
      iex> state = %{
      ...>   string: program,
      ...>   statements: [],
      ...>   current: %{line_number: 0, element: %{label: "", instruction: {}}}
      ...> }
      iex> parse_program(state)
      [
        {:ok, {3, %{label: "foo", instruction: {"j", "foo"}}}},
        {:ok, {2, %{label: "", instruction: {"add", "$t0", "$t1", "$t2"}}}},
        {:ok, {1, %{label: "_start", instruction: {}}}}
      ]
  """
  def parse_program(%{string: "", statements: statements}), do: statements

  def parse_program(state) do
    state
    |> parse_stmt()
    |> next_stmt()
    |> parse_program()
  end

  @doc ~S"""
  stmt

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_stmt: 1]
      iex> state = %{
      ...>   string: "\t foo: add $t0, $t1, $t2\t \n",
      ...>   current: %{line_number: 0, element: %{label: "", instruction: {}}}
      ...> }
      iex> parse_stmt(state)
      {
        :ok,
        %{
          string: "",
          current: %{line_number: 1, element: %{label: "foo", instruction: {"add", "$t0", "$t1", "$t2"}}}
        }
      }
      iex> state = %{string: "\t \t\n", current: %{line_number: 0, element: %{label: "", instruction: {}}}}
      iex> parse_stmt(state)
      {:ok, %{string: "", current: %{line_number: 1, element: %{label: "", instruction: {}}}}}
  """

  def parse_stmt(state) do
    case {parse_stmt_one(state), parse_stmt_two(state)} do
      {ok = {:ok, _state}, _} -> ok
      {_, ok = {:ok, _state}} -> ok
      _ -> error(state)
    end
  end

  defp parse_stmt_one(state) do
    state
    |> ok()
    |> chain(&skip_white_space/1)
    |> chain(&parse_stat/1)
    |> chain(&skip_white_space/1)
    |> chain(&parse_new_line_or_eof/1)
  end

  defp parse_stmt_two(state) do
    state
    |> ok()
    |> chain(&skip_white_space/1)
    |> chain(&parse_new_line_or_eof/1)
  end

  defp parse_new_line_or_eof(state) do
    case {parse_new_line(state), parse_eof(state)} do
      {ok = {:ok, _state}, _} -> ok
      {_, ok = {:ok, _state}} -> ok
      _ -> error(state)
    end
  end

  defp next_stmt(
         {:ok,
          state = %{
            statements: statements,
            current: %{line_number: line_number, element: element}
          }}
       ) do
    statement = ok({line_number, element})

    state
    |> put_in([:statements], [statement | statements])
    |> put_in([:current, :element], @init_element)
  end

  defp next_stmt({:error, state}) do
    state
    |> skip_current_statement()
    |> put_in([:current, :element], @init_element)
  end

  defp skip_current_statement(
         state = %{
           string: string,
           statements: statements,
           current: %{line_number: line_number, element: element}
         }
       ) do
    rest = Regex.replace(~r{^.*\n}f, string, "")
    statement = error({line_number + 1, element})

    state
    |> put_in([:string], rest)
    |> put_in([:statements], [statement | statements])
    |> put_in([:current, :line_number], line_number + 1)
  end

  @doc """
  stat

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_stat: 1]
      iex> state = %{
      ...>   string: "foo: add $t0, $t1, $t2",
      ...>   current: %{line_number: 0, element: %{label: "", instruction: {}}}
      ...> }
      iex> parse_stat(state)
      {
        :ok,
        %{
          string: "",
          current: %{line_number: 0, element: %{label: "foo", instruction: {"add", "$t0", "$t1", "$t2"}}}
        }
      }
      iex> state = %{
      ...>   string: "foo:",
      ...>   current: %{line_number: 0, element: %{label: "", instruction: {}}}
      ...> }
      iex> parse_stat(state)
      {
        :ok,
        %{
          string: "",
          current: %{line_number: 0, element: %{label: "foo", instruction: {}}}
        }
      }
      iex> state = %{
      ...>   string: "add $t0, $t1, $t2",
      ...>   current: %{line_number: 0, element: %{label: "", instruction: {}}}
      ...> }
      iex> parse_stat(state)
      {
        :ok,
        %{
          string: "",
          current: %{line_number: 0, element: %{label: "", instruction: {"add", "$t0", "$t1", "$t2"}}}
        }
      }
  """
  def parse_stat(state) do
    case {parse_stat_one(state), parse_stat_two(state), parse_stat_three(state)} do
      {ok = {:ok, _state}, _, _} -> ok
      {_, ok = {:ok, _state}, _} -> ok
      {_, _, ok = {:ok, _state}} -> ok
      _ -> error(state)
    end
  end

  defp parse_stat_one(state) do
    state
    |> ok()
    |> chain(&parse_label/1)
    |> chain(&skip_white_space/1)
    |> chain(&parse_instruction/1)
  end

  defp parse_stat_two(state) do
    state
    |> ok()
    |> chain(&parse_label/1)
  end

  defp parse_stat_three(state) do
    state
    |> ok()
    |> chain(&parse_instruction/1)
  end

  @doc """
  label

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_label: 1]
      iex> parse_label(%{string: "_foo:", current: %{element: %{instruction: {}}}})
      {:ok, %{string: "", current: %{element: %{label: "_foo", instruction: {}}}}}
      iex> parse_label(%{string: "_foo", current: %{element: %{instruction: {}}}})
      {:error, %{string: "", current: %{element: %{label: "_foo", instruction: {}}}}}
  """
  # def parse_label(state = %{string: string, current: current = %{element: element}}) do
  def parse_label(state) do
    state
    |> ok()
    |> chain(&parse_identifier(&1, path: [:current, :element, :label]))
    |> chain(&parse_colon/1)
  end

  @doc ~S"""
  instruction

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_instruction: 1]
      iex> state = %{string: "add $t0, $t1, $t2", current: %{line_number: 0, element: %{instruction: {}}}}
      iex> parse_instruction(state)
      {:ok, %{string: "", current: %{line_number: 0, element: %{instruction: {"add", "$t0", "$t1", "$t2"}}}}}
      iex> parse_instruction(%{state | string: "mult $t0, $t1"})
      {:ok, %{string: "", current: %{line_number: 0, element: %{instruction: {"mult", "$t0", "$t1"}}}}}
      iex> parse_instruction(%{state | string: "j foo\nhoge"})
      {:ok, %{string: "\nhoge", current: %{line_number: 0, element: %{instruction: {"j", "foo"}}}}}
      iex> parse_instruction(%{state | string: "add$t0,$t1,$t2"})
      {:error, %{string: "add$t0,$t1,$t2", current: %{line_number: 0, element: %{instruction: {}}}}}
  """
  def parse_instruction(state) do
    parse_optional = fn state ->
      state
      |> ok()
      |> chain(&skip_white_space/1)
      |> chain(&parse_comma/1)
      |> chain(&skip_white_space/1)
      |> chain(&parse_operand/1)
      |> case do
        ok = {:ok, _state} -> ok
        {:error, state} -> ok(state)
      end
    end

    state
    |> ok()
    |> chain(&parse_op_code/1)
    |> chain(&skip_white_space/1)
    |> chain(&parse_operand/1)
    |> case do
      err = {:error, _state} ->
        err

      {:ok, state} ->
        state
        |> ok()
        |> chain(parse_optional)
        |> chain(parse_optional)
    end
  end

  @doc """
  op_code

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_op_code: 1]
      iex> state = %{string: "add $t0, $t1, $t2", current: %{element: %{instruction: {}}}}
      iex> parse_op_code(state)
      {:ok, %{string: "$t0, $t1, $t2", current: %{element: %{instruction: {"add"}}}}}
      iex> parse_op_code(%{state | string: "aff $t0, $t1, $t2"})  # Parsing is possible.
      {:ok, %{string: "$t0, $t1, $t2", current: %{element: %{instruction: {"aff"}}}}}
  """
  def parse_op_code(
        state = %{
          string: string,
          current: %{element: %{instruction: instruction}}
        }
      ) do
    case Regex.split(~r{\t| }f, string, parts: 2) do
      [op_code, rest] ->
        instruction = Tuple.append(instruction, op_code)

        state
        |> put_in([:current, :element, :instruction], instruction)
        |> put_in([:string], rest)
        |> ok()

      _ ->
        error(state)
    end
  end

  def parse_op_code(state), do: error(state)

  @doc ~S"""
  operand

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_operand: 1]
      iex> state = %{string: "$t0", current: %{element: %{instruction: {"lw"}}}}
      iex> parse_operand(state)
      {:ok, %{string: "", current: %{element: %{instruction: {"lw", "$t0"}}}}}
      iex> parse_operand(%{state | string: "($t0)"})
      {:ok, %{string: "", current: %{element: %{instruction: {"lw", "$t0"}}}}}
      iex> parse_operand(%{state | string: "-4($t0)"})
      {:ok, %{string: "", current: %{element: %{instruction: {"lw", "-4", "$t0"}}}}}
      iex> parse_operand(%{string: "foo\nbaz", current: %{line_number: 0, element: %{instruction: {"j"}}}})
      {:ok, %{string: "\nbaz", current: %{line_number: 0, element: %{instruction: {"j", "foo"}}}}}
      iex> parse_operand(%{state | string: "foo($t0)"})  # Parsing is possible.
      {:ok, %{string: "($t0)", current: %{element: %{instruction: {"lw", "foo"}}}}}
  """
  def parse_operand(state) do
    case {parse_operand_one(state), parse_operand_two(state), parse_operand_three(state),
          parse_operand_four(state)} do
      {ok = {:ok, _state}, _, _, _} -> ok
      {_, ok = {:ok, _state}, _, _} -> ok
      {_, _, ok = {:ok, _state}, _} -> ok
      {_, _, _, ok = {:ok, _state}} -> ok
      _ -> error(state)
    end
  end

  defp parse_operand_one(state) do
    state
    |> ok()
    |> chain(&parse_register/1)
  end

  defp parse_operand_two(state) do
    state
    |> ok()
    |> chain(&parse_right_round_bracket/1)
    |> chain(&skip_white_space/1)
    |> chain(&parse_register/1)
    |> chain(&skip_white_space/1)
    |> chain(&parse_left_round_bracket/1)
  end

  defp parse_operand_three(state) do
    parse_optional = fn state ->
      state
      |> ok()
      |> chain(&parse_right_round_bracket/1)
      |> chain(&skip_white_space/1)
      |> chain(&parse_register/1)
      |> chain(&skip_white_space/1)
      |> chain(&parse_left_round_bracket/1)
      |> case do
        ok = {:ok, _state} -> ok
        {:error, state} -> ok(state)
      end
    end

    state
    |> ok()
    |> chain(&parse_addr_immd/1)
    |> chain(&skip_white_space/1)
    |> case do
      err = {:error, _state} ->
        err

      {:ok, state} ->
        state
        |> parse_optional.()
    end
  end

  defp parse_operand_four(state) do
    state
    |> ok()
    |> chain(&parse_identifier(&1, path: [:current, :element, :instruction]))
  end

  @doc """
  register

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_register: 1]
      iex> state = %{string: "$t0, $t1, $t2", current: %{element: %{instruction: {"add"}}}}
      iex> parse_register(state)
      {:ok, %{string: ", $t1, $t2", current: %{element: %{instruction: {"add", "$t0"}}}}}
      iex> parse_register(%{state | string: "foo"})
      {:error, %{string: "foo", current: %{element: %{instruction: {"add"}}}}}
  """
  def parse_register(state = %{string: string, current: %{element: %{instruction: instruction}}}) do
    case _parse_register(string) do
      {"", ^string} ->
        error(state)

      {register, rest} ->
        state
        |> put_in([:current, :element, :instruction], Tuple.append(instruction, register))
        |> put_in([:string], rest)
        |> ok()
    end
  end

  def parse_register(state), do: error(state)

  defp _parse_register("$zero" <> rest), do: {"$zero", rest}
  defp _parse_register("$at" <> rest), do: {"$at", rest}
  defp _parse_register("$v0" <> rest), do: {"$v0", rest}
  defp _parse_register("$v1" <> rest), do: {"$v1", rest}
  defp _parse_register("$v2" <> rest), do: {"$v2", rest}
  defp _parse_register("$a0" <> rest), do: {"$a0", rest}
  defp _parse_register("$a1" <> rest), do: {"$a1", rest}
  defp _parse_register("$a2" <> rest), do: {"$a2", rest}
  defp _parse_register("$a3" <> rest), do: {"$a3", rest}
  defp _parse_register("$t0" <> rest), do: {"$t0", rest}
  defp _parse_register("$t1" <> rest), do: {"$t1", rest}
  defp _parse_register("$t2" <> rest), do: {"$t2", rest}
  defp _parse_register("$t3" <> rest), do: {"$t3", rest}
  defp _parse_register("$t4" <> rest), do: {"$t4", rest}
  defp _parse_register("$t5" <> rest), do: {"$t5", rest}
  defp _parse_register("$t6" <> rest), do: {"$t6", rest}
  defp _parse_register("$t7" <> rest), do: {"$t7", rest}
  defp _parse_register("$t8" <> rest), do: {"$t8", rest}
  defp _parse_register("$t9" <> rest), do: {"$t9", rest}
  defp _parse_register("$s0" <> rest), do: {"$s0", rest}
  defp _parse_register("$s1" <> rest), do: {"$s1", rest}
  defp _parse_register("$s2" <> rest), do: {"$s2", rest}
  defp _parse_register("$s3" <> rest), do: {"$s3", rest}
  defp _parse_register("$s4" <> rest), do: {"$s4", rest}
  defp _parse_register("$s5" <> rest), do: {"$s5", rest}
  defp _parse_register("$s6" <> rest), do: {"$s6", rest}
  defp _parse_register("$s7" <> rest), do: {"$s7", rest}
  defp _parse_register("$k0" <> rest), do: {"$k0", rest}
  defp _parse_register("$k1" <> rest), do: {"$k1", rest}
  defp _parse_register("$gp" <> rest), do: {"$gp", rest}
  defp _parse_register("$sp" <> rest), do: {"$sp", rest}
  defp _parse_register("$fp" <> rest), do: {"$fp", rest}
  defp _parse_register("$ra" <> rest), do: {"$ra", rest}
  defp _parse_register(string), do: {"", string}

  @doc """
  addr immd

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_addr_immd: 1]
      iex> state = %{string: "-4($t0)", current: %{element: %{instruction: {"lw"}}}}
      iex> parse_addr_immd(state)
      {:ok, %{string: "($t0)", current: %{element: %{instruction: {"lw", "-4"}}}}}
      iex> parse_addr_immd(%{state | string: "foo"})
      {:error, %{string: "foo", current: %{element: %{instruction: {"lw"}}}}}
  """
  def parse_addr_immd(state = %{string: string, current: %{element: %{instruction: instruction}}}) do
    case Regex.split(~r{^(\+|\-)?[[:blank:]]*\d+}f, string, trim: true, include_captures: true) do
      [addr_immd, rest] ->
        state
        |> put_in([:current, :element, :instruction], Tuple.append(instruction, addr_immd))
        |> put_in([:string], rest)
        |> ok()

      _ ->
        error(state)
    end
  end

  def parse_addr_immd(state), do: error(state)

  @doc """
  white space

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_white_space: 1]
      iex> parse_white_space(%{string: " \tfoo \t"})
      {:ok, %{string: "\tfoo \t"}}
      iex> parse_white_space(%{string: "foo"})
      {:error, %{string: "foo"}}
  """
  def parse_white_space(state = %{string: <<char::bytes-size(1)>> <> rest})
      when char === " " or char === "\t",
      do: ok(%{state | string: rest})

  def parse_white_space(state), do: error(state)

  @doc ~S"""
  new line

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_new_line: 1]
      iex> state = %{string: "\nfoo", current: %{line_number: 0}}
      iex> parse_new_line(state)
      {:ok, %{string: "foo", current: %{line_number: 1}}}
      iex> parse_new_line(%{state | string: "foo"})
      {:error, %{string: "foo", current: %{line_number: 0}}}
  """
  def parse_new_line(state = %{string: "\n" <> rest, current: %{line_number: line_number}}) do
    state
    |> put_in([:current, :line_number], line_number + 1)
    |> put_in([:string], rest)
    |> ok()
  end

  def parse_new_line(state = %{string: "\r\n" <> rest, current: %{line_number: line_number}}) do
    state
    |> put_in([:current, :line_number], line_number + 1)
    |> put_in([:string], rest)
    |> ok()
  end

  def parse_new_line(state), do: error(state)

  @doc """
  string_end

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_eof: 1]
      iex> parse_eof(%{string: "", current: %{line_number: 0}})
      {:ok, %{string: "", current: %{line_number: 1}}}
      iex> parse_eof(%{string: "foo"})
      {:error, %{string: "foo"}}
  """
  def parse_eof(state = %{string: "", current: %{line_number: line_number}}) do
    state
    |> put_in([:current, :line_number], line_number + 1)
    |> ok()
  end

  # def parse_eof(state = %{string: ""}), do: ok(state)
  def parse_eof(state), do: error(state)

  @doc ~S"""
  identifier

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_identifier: 2]
      iex> state = %{string: "foo", current: %{element: %{label: "", instruction: {"j"}}}}
      iex> parse_identifier(state, path: [:current, :element, :instruction])
      {:ok, %{string: "", current: %{element: %{label: "", instruction: {"j", "foo"}}}}}
      iex> state = %{string: "_foo:", current: %{element: %{label: "", instruction: {}}}}
      iex> parse_identifier(state, path: [:current, :element, :label])
      {:ok, %{string: ":", current: %{element: %{label: "_foo", instruction: {}}}}}
      iex> state = %{string: "foo\nbar", current: %{element: %{label: "", instruction: {"j"}}}}
      iex> parse_identifier(state, path: [:current, :element, :instruction])
      {:ok, %{string: "\nbar", current: %{element: %{label: "", instruction: {"j", "foo"}}}}}
  """
  def parse_identifier(
        state = %{string: string, current: %{element: %{instruction: instruction}}},
        path: path
      ) do
    case Regex.split(~r{^([a-zA-Z]|_)([a-zA-Z]|\d|_)*}f, string,
           include_captures: true,
           trim: true
         ) do
      [label, rest] -> {label, rest}
      [label] -> {label, ""}
      _ -> {"", ""}
    end
    |> case do
      {"", ""} ->
        error(state)

      {label, rest} ->
        put_in_selectively = fn state ->
          case path do
            [:current, :element, :instruction] ->
              put_in(state, path, Tuple.append(instruction, label))

            [:current, :element, :label] ->
              put_in(state, path, label)
          end
        end

        state
        |> put_in_selectively.()
        |> put_in([:string], rest)
        |> ok()
    end
  end

  def parse_identifier(state, _path), do: error(state)

  @doc """
  right round bracket

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_right_round_bracket: 1]
      iex> parse_right_round_bracket(%{string: "(foo"})
      {:ok, %{string: "foo"}}
      iex> parse_right_round_bracket(%{string: "foo"})
      {:error, %{string: "foo"}}
  """
  def parse_right_round_bracket(state = %{string: "(" <> rest}),
    do: put_in(state, [:string], rest) |> ok()

  def parse_right_round_bracket(state), do: error(state)

  @doc """
  left round bracket

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_left_round_bracket: 1]
      iex> parse_left_round_bracket(%{string: ")foo"})
      {:ok, %{string: "foo"}}
      iex> parse_left_round_bracket(%{string: "foo"})
      {:error, %{string: "foo"}}
  """
  def parse_left_round_bracket(state = %{string: ")" <> rest}),
    do: put_in(state, [:string], rest) |> ok()

  def parse_left_round_bracket(state), do: error(state)

  @doc """
  comma

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_comma: 1]
      iex> parse_comma(%{string: ",foo"})
      {:ok, %{string: "foo"}}
      iex> parse_comma(%{string: "foo"})
      {:error, %{string: "foo"}}
  """
  def parse_comma(state = %{string: "," <> rest}), do: put_in(state, [:string], rest) |> ok()
  def parse_comma(state), do: error(state)

  @doc """
  colon

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_colon: 1]
      iex> parse_colon(%{string: ": foo"})
      {:ok, %{string: " foo"}}
      iex> parse_colon(%{string: "foo"})
      {:error, %{string: "foo"}}
  """
  def parse_colon(state = %{string: ":" <> rest}), do: put_in(state, [:string], rest) |> ok()
  def parse_colon(state), do: error(state)

  @doc """
  white space

  ## Example
      iex> import MipsAssembler.Parser, only: [skip_white_space: 1]
      iex> skip_white_space(%{string: " \tfoo \t"})
      {:ok, %{string: "foo \t"}}
      iex> skip_white_space(%{string: "foo"})
      {:ok, %{string: "foo"}}
  """
  def skip_white_space(state = %{string: <<char::bytes-size(1)>> <> rest})
      when char === " " or char === "\t",
      do: skip_white_space(%{state | string: rest})

  def skip_white_space(state), do: ok(state)
end
