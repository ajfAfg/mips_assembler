defmodule MipsAssembler.Parser do
  @init_element %{label: "", operand: {}}

  @moduledoc """
  ok
  """

  import MipsAssembler.Either, only: [ok: 1, error: 1, chain: 2]

  def parse(string) do
    string
    |> init()
    |> parse_program()
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
      ...>   current: %{line_number: 0, element: %{label: "", operand: {}}}
      ...> }
      iex> parse_program(state)
      [
        {:ok, {3, %{label: "foo", operand: {"j", "foo"}}}},
        {:ok, {2, %{label: "", operand: {"add", "$t0", "$t1", "$t2"}}}},
        {:ok, {1, %{label: "_start", operand: {}}}}
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
      ...>   current: %{line_number: 0, element: %{label: "", operand: {}}}
      ...> }
      iex> parse_stmt(state)
      {
        :ok,
        %{
          string: "",
          current: %{line_number: 1, element: %{label: "foo", operand: {"add", "$t0", "$t1", "$t2"}}}
        }
      }
      iex> state = %{string: "\t \t\n", current: %{line_number: 0, element: %{label: "", operand: {}}}}
      iex> parse_stmt(state)
      {:ok, %{string: "", current: %{line_number: 1, element: %{label: "", operand: {}}}}}
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
    parse_one = fn state ->
      state
      |> ok()
      |> chain(&parse_new_line/1)
    end

    parse_two = fn state ->
      state
      |> ok()
      |> chain(&parse_eof/1)
    end

    case {parse_one.(state), parse_two.(state)} do
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
           current: %{line_number: line_number}
         }
       ) do
    rest = Regex.replace(~r{^.*\n}f, string, "")
    statement = error({line_number, @init_element})
    %{state | string: rest, statements: [statement | statements]}
  end

  @doc """
  stat

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_stat: 1]
      iex> state = %{
      ...>   string: "foo: add $t0, $t1, $t2",
      ...>   current: %{line_number: 0, element: %{label: "", operand: {}}}
      ...> }
      iex> parse_stat(state)
      {
        :ok,
        %{
          string: "",
          current: %{line_number: 0, element: %{label: "foo", operand: {"add", "$t0", "$t1", "$t2"}}}
        }
      }
      iex> state = %{
      ...>   string: "foo:",
      ...>   current: %{line_number: 0, element: %{label: "", operand: {}}}
      ...> }
      iex> parse_stat(state)
      {
        :ok,
        %{
          string: "",
          current: %{line_number: 0, element: %{label: "foo", operand: {}}}
        }
      }
      iex> state = %{
      ...>   string: "add $t0, $t1, $t2",
      ...>   current: %{line_number: 0, element: %{label: "", operand: {}}}
      ...> }
      iex> parse_stat(state)
      {
        :ok,
        %{
          string: "",
          current: %{line_number: 0, element: %{label: "", operand: {"add", "$t0", "$t1", "$t2"}}}
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
      iex> parse_label(%{string: "_foo:", current: %{element: %{operand: {}}}})
      {:ok, %{string: "", current: %{element: %{label: "_foo", operand: {}}}}}
      iex> parse_label(%{string: "_foo", current: %{element: %{operand: {}}}})
      {:error, %{string: "", current: %{element: %{label: "_foo", operand: {}}}}}
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
      iex> state = %{string: "add $t0, $t1, $t2", current: %{line_number: 0, element: %{operand: {}}}}
      iex> parse_instruction(state)
      {:ok, %{string: "", current: %{line_number: 0, element: %{operand: {"add", "$t0", "$t1", "$t2"}}}}}
      iex> parse_instruction(%{state | string: "mult $t0, $t1"})
      {:ok, %{string: "", current: %{line_number: 0, element: %{operand: {"mult", "$t0", "$t1"}}}}}
      iex> parse_instruction(%{state | string: "j foo\nhoge"})
      {:ok, %{string: "hoge", current: %{line_number: 1, element: %{operand: {"j", "foo"}}}}}
      iex> parse_instruction(%{state | string: "add$t0,$t1,$t2"})
      {:error, %{string: "$t0,$t1,$t2", current: %{line_number: 0, element: %{operand: {"add"}}}}}
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
    |> chain(&parse_white_space/1)
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
      iex> state = %{string: "add $t0, $t1, $t2", current: %{element: %{operand: {}}}}
      iex> parse_op_code(state)
      {:ok, %{string: " $t0, $t1, $t2", current: %{element: %{operand: {"add"}}}}}
      iex> parse_op_code(%{state | string: "aff $t0, $t1, $t2"})
      {:error, %{string: "aff $t0, $t1, $t2", current: %{element: %{operand: {}}}}}
  """
  def parse_op_code(
        state = %{
          string: string,
          current: %{element: %{operand: operand}}
        }
      ) do
    case _parse_op_code(string) do
      {"", ^string} ->
        error(state)

      {op_code, rest} ->
        operand = Tuple.append(operand, op_code)

        state
        |> put_in([:current, :element, :operand], operand)
        |> put_in([:string], rest)
        |> ok()
    end
  end

  def parse_op_code(state), do: error(state)

  defp _parse_op_code("add" <> rest), do: {"add", rest}
  defp _parse_op_code("sub" <> rest), do: {"sub", rest}
  defp _parse_op_code("mult" <> rest), do: {"mult", rest}
  defp _parse_op_code("div" <> rest), do: {"div", rest}
  defp _parse_op_code("addi" <> rest), do: {"addi", rest}
  defp _parse_op_code("addu" <> rest), do: {"addu", rest}
  defp _parse_op_code("subu" <> rest), do: {"subu", rest}
  defp _parse_op_code("multu" <> rest), do: {"multu", rest}
  defp _parse_op_code("divu" <> rest), do: {"divu", rest}
  defp _parse_op_code("addiu" <> rest), do: {"addiu", rest}
  defp _parse_op_code("and" <> rest), do: {"and", rest}
  defp _parse_op_code("or" <> rest), do: {"or", rest}
  defp _parse_op_code("nor" <> rest), do: {"nor", rest}
  defp _parse_op_code("xor" <> rest), do: {"xor", rest}
  defp _parse_op_code("andi" <> rest), do: {"andi", rest}
  defp _parse_op_code("ori" <> rest), do: {"ori", rest}
  defp _parse_op_code("xori" <> rest), do: {"xori", rest}
  defp _parse_op_code("sll" <> rest), do: {"sll", rest}
  defp _parse_op_code("srl" <> rest), do: {"srl", rest}
  defp _parse_op_code("sllv" <> rest), do: {"sllv", rest}
  defp _parse_op_code("srlv" <> rest), do: {"srlv", rest}
  defp _parse_op_code("sra" <> rest), do: {"sra", rest}
  defp _parse_op_code("srav" <> rest), do: {"srav", rest}
  defp _parse_op_code("lw" <> rest), do: {"lw", rest}
  defp _parse_op_code("sw" <> rest), do: {"sw", rest}
  defp _parse_op_code("mfhi" <> rest), do: {"mfhi", rest}
  defp _parse_op_code("mflo" <> rest), do: {"mflo", rest}
  defp _parse_op_code("mthi" <> rest), do: {"mthi", rest}
  defp _parse_op_code("mtlo" <> rest), do: {"mtlo", rest}
  defp _parse_op_code("slt" <> rest), do: {"slt", rest}
  defp _parse_op_code("sltu" <> rest), do: {"sltu", rest}
  defp _parse_op_code("slti" <> rest), do: {"slti", rest}
  defp _parse_op_code("sltiu" <> rest), do: {"sltiu", rest}
  defp _parse_op_code("beq" <> rest), do: {"beq", rest}
  defp _parse_op_code("bne" <> rest), do: {"bne", rest}
  defp _parse_op_code("bgez" <> rest), do: {"bgez", rest}
  defp _parse_op_code("bgtz" <> rest), do: {"bgtz", rest}
  defp _parse_op_code("blez" <> rest), do: {"blez", rest}
  defp _parse_op_code("bltz" <> rest), do: {"bltz", rest}
  defp _parse_op_code("j" <> rest), do: {"j", rest}
  defp _parse_op_code("jal" <> rest), do: {"jal", rest}
  defp _parse_op_code("jr" <> rest), do: {"jr", rest}
  defp _parse_op_code("jalr" <> rest), do: {"jalr", rest}
  defp _parse_op_code(string), do: {"", string}

  @doc ~S"""
  operand

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_operand: 1]
      iex> state = %{string: "$t0", current: %{element: %{operand: {"lw"}}}}
      iex> parse_operand(state)
      {:ok, %{string: "", current: %{element: %{operand: {"lw", "$t0"}}}}}
      iex> parse_operand(%{state | string: "($t0)"})
      {:ok, %{string: "", current: %{element: %{operand: {"lw", "$t0"}}}}}
      iex> parse_operand(%{state | string: "-4($t0)"})
      {:ok, %{string: "", current: %{element: %{operand: {"lw", "-4", "$t0"}}}}}
      iex> parse_operand(%{string: "foo\nbaz", current: %{line_number: 0, element: %{operand: {"j"}}}})
      {:ok, %{string: "baz", current: %{line_number: 1, element: %{operand: {"j", "foo"}}}}}
      iex> parse_operand(%{state | string: "foo($t0)"})
      {:error, %{string: "foo($t0)", current: %{element: %{operand: {"lw"}}}}}
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
    parse_white_space_or_new_line_or_word_end = fn state ->
      case {parse_white_space(state), parse_new_line(state), parse_word_end(state)} do
        {ok = {:ok, _state}, _, _} -> ok
        {_, ok = {:ok, _state}, _} -> ok
        {_, _, ok = {:ok, _state}} -> ok
        _ -> error(state)
      end
    end

    state
    |> ok()
    |> chain(&parse_identifier(&1, path: [:current, :element, :operand]))
    |> chain(parse_white_space_or_new_line_or_word_end)
  end

  @doc """
  register

  ## Example
      iex> import MipsAssembler.Parser, only: [parse_register: 1]
      iex> state = %{string: "$t0, $t1, $t2", current: %{element: %{operand: {"add"}}}}
      iex> parse_register(state)
      {:ok, %{string: ", $t1, $t2", current: %{element: %{operand: {"add", "$t0"}}}}}
      iex> parse_register(%{state | string: "foo"})
      {:error, %{string: "foo", current: %{element: %{operand: {"add"}}}}}
  """
  def parse_register(state = %{string: string, current: %{element: %{operand: operand}}}) do
    case _parse_register(string) do
      {"", ^string} ->
        error(state)

      {register, rest} ->
        state
        |> put_in([:current, :element, :operand], Tuple.append(operand, register))
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
  defp _parse_register("$a1" <> rest), do: {"$a0", rest}
  defp _parse_register("$a2" <> rest), do: {"$a1", rest}
  defp _parse_register("$a3" <> rest), do: {"$a2", rest}
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
      iex> state = %{string: "-4($t0)", current: %{element: %{operand: {"lw"}}}}
      iex> parse_addr_immd(state)
      {:ok, %{string: "($t0)", current: %{element: %{operand: {"lw", "-4"}}}}}
      iex> parse_addr_immd(%{state | string: "foo"})
      {:error, %{string: "foo", current: %{element: %{operand: {"lw"}}}}}
  """
  def parse_addr_immd(state = %{string: string, current: %{element: %{operand: operand}}}) do
    case Regex.split(~r{^(\+|\-)?[[:blank:]]*\d+}f, string, trim: true, include_captures: true) do
      [addr_immd, rest] ->
        state
        |> put_in([:current, :element, :operand], Tuple.append(operand, addr_immd))
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
      iex> state = %{string: "foo", current: %{element: %{label: "", operand: {"j"}}}}
      iex> parse_identifier(state, path: [:current, :element, :operand])
      {:ok, %{string: "", current: %{element: %{label: "", operand: {"j", "foo"}}}}}
      iex> state = %{string: "_foo:", current: %{element: %{label: "", operand: {}}}}
      iex> parse_identifier(state, path: [:current, :element, :label])
      {:ok, %{string: ":", current: %{element: %{label: "_foo", operand: {}}}}}
      iex> state = %{string: "foo\nbar", current: %{element: %{label: "", operand: {"j"}}}}
      iex> parse_identifier(state, path: [:current, :element, :operand])
      {:ok, %{string: "\nbar", current: %{element: %{label: "", operand: {"j", "foo"}}}}}
  """
  def parse_identifier(
        state = %{string: string, current: %{element: %{operand: operand}}},
        path: path
      ) do
    # case Regex.split(~r{^([[:alpha]]|_)([[:alpha:]]|\d|_)*}f, string,
    case Regex.split(~r{^([a-zA-Z]|_)([a-zA-Z]|\d|_)*}f, string,
           # case Regex.split(~r{^([[:alpha]]|_)(\w|\d|_)*}f, string,
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
            [:current, :element, :operand] ->
              put_in(state, path, Tuple.append(operand, label))

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

  def parse_word_end(state = %{string: ""}), do: ok(state)
  def parse_word_end(state), do: error(state)

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
