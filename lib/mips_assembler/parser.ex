defmodule MipsAssembler.Parser do
  @moduledoc """
  ok
  """

  @init_element %{label: "", operand: {}}

  def parse(string) do
    string
    |> init()
    |> parse_program()
  end

  def init(string),
    do: %{
      string: remove_comment(string),
      statements: [],
      current: %{line_number: 0, element: @init_element}
    }

  def remove_comment(string), do: String.replace(string, ~r{#.*}, "")

  def parse_program(%{string: "", statements: statements}), do: statements

  def parse_program(state) do
    state
    |> parse_stmt()
    |> next_stmt()
    |> parse_program()
  end

  defp next_stmt({:error, state}) do
    state
    |> skip_current_statement()
    |> put_in([:current, :element], @init_element)
  end

  # defp next_stmt(state = %{current: current}),
  #   do: %{state | current: %{current | element: %{lebel: "", operand: {}}}}
  defp next_stmt(
         state = %{statements: statements, current: %{line_number: line_number, element: element}}
       ) do
    statement = {:ok, {line_number, element}}

    state
    |> put_in([:statements], [statement | statements])
    |> put_in([:current, :element], @init_element)
  end

  defp skip_current_statement(
         state = %{
           string: string,
           statements: statements,
           current: %{line_number: line_number}
         }
       ) do
    rest = String.trim_leading(string, "\n")
    statement = {:error, {line_number, @init_element}}
    %{state | string: rest, statements: [statement | statements]}
  end

  def parse_stmt(error = {:error, _state}), do: error

  def parse_stmt(state) do
    case {parse_stmt_one(state), parse_stmt_two(state)} do
      {{:error, _}, state} -> state
      {state, _} -> state
    end
  end

  defp parse_stmt_one(state) do
    state
    |> parse_white_space()
    |> parse_stat()
    |> parse_white_space()
    |> parse_new_line()
  end

  defp parse_stmt_two(state) do
    state
    |> parse_white_space()
    |> parse_new_line()
    |> case do
      {:error, state} -> state
      state -> state
    end
  end

  #   def parse_stmt(%{string: "\n" <> rest, statements: statements}) do
  #     statement = {:ok, {length(statements), %{}}}
  #     %{string: rest, statements: [statement | statements]}
  #   end
  #
  #   def parse_stmt(state) do
  #     state
  #     |> parse_stat()
  #     |> parse_white_space()
  #     |> parse_stmt_end()
  #   end

  def parse_stat(error = {:error, _state}), do: error

  def parse_stat(state) do
    case {parse_stat_one(state), parse_stat_two(state), parse_stat_three(state)} do
      {{:error, _}, {:error, _}, state} -> state
      {{:error, _}, state, _} -> state
      {state, _, _} -> state
    end
  end

  defp parse_stat_one(state) do
    state
    |> parse_label()
    |> parse_white_space()
    |> parse_instruction()
  end

  defp parse_stat_two(state) do
    state
    |> parse_label()
  end

  defp parse_stat_three(state) do
    state
    |> parse_instruction()
  end

  def parse_label(error = {:error, _state}), do: error

  def parse_label(state = %{string: string, current: current = %{element: element}}) do
    case Regex.split(~r{^([[:alpha]]|_)([[:alpha:]]|\d|_)*:}f, string, include_captures: true) do
      [label, rest] ->
        element = %{element | label: label}
        %{state | string: rest, current: %{current | element: element}}

      _ ->
        {:error, state}
    end
  end

  def parse_instruction(error = {:error, _state}), do: error

  def parse_instruction(state) do
    parse_optional = fn state ->
      state
      |> parse_white_space()
      |> parse_comma()
      |> parse_white_space()
      |> parse_operand()
    end

    state
    |> parse_op_code()
    |> parse_white_space()
    |> parse_operand()
    |> parse_white_space()
    |> parse_optional.()
    |> case do
      {:error, state} ->
        state

      state ->
        parse_optional.(state)
        |> case do
          {:error, state} -> state
          state -> state
        end
    end
  end

  def parse_op_code(error = {:error, _state}), do: error

  def parse_op_code(
        state = %{
          string: string,
          current: %{element: %{operand: operand}}
        }
      ) do
    {op_code, rest} = _parse_op_code(string)
    operand = Tuple.append(operand, op_code)

    state
    |> put_in([:current, :element, :operand], operand)
    |> put_in([:string], rest)
  end

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

  def parse_operand(error = {:error, _state}), do: error

  def parse_operand(state) do
    case {parse_operand_one(state), parse_operand_two(state), parse_operand_three(state)} do
      {{:error, _}, {:error, _}, state} ->
        state

      {{:error, _}, state, _} ->
        state

      {state, _, _} ->
        state
    end
  end

  defp parse_operand_one(state) do
    state
    |> parse_register()
  end

  defp parse_operand_two(state) do
    state
    |> parse_right_round_bracket()
    |> parse_white_space()
    |> parse_register()
    |> parse_white_space()
    |> parse_left_round_bracket()
  end

  def parse_operand_three(state) do
    state
    |> parse_addr_immd()
    |> parse_white_space()
    |> Kernel.then(fn state ->
      state
      |> parse_right_round_bracket()
      |> parse_white_space()
      |> parse_register()
      |> parse_white_space()
      |> parse_left_round_bracket()
    end)
    |> case do
      {:error, state} -> state
      state -> state
    end
  end

  def parse_register(error = {:error, _state}), do: error

  def parse_register(state = %{string: string, current: %{element: %{operand: operand}}}) do
    {register, rest} = _parse_register(string)

    state
    |> put_in([:current, :element, :operand], Tuple.append(operand, register))
    |> put_in([:string], rest)
  end

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

  def parse_addr_immd(error = {:error, _state}), do: error

  def parse_addr_immd(state = %{string: string, current: %{element: %{operand: operand}}}) do
    case Regex.split(~r{^(\+|\-)?[[:blank:]]*\d+}f, string, trim: true, include_captures: true) do
      [addr_immd, rest] ->
        state
        |> put_in([:current, :element, :operand], Tuple.append(operand, addr_immd))
        |> put_in([:string], rest)

      _ ->
        {:error, state}
    end
  end

  def parse_white_space(state = %{string: <<char::bytes-size(1)>> <> rest})
      when char === " " or char === "\t",
      do: parse_white_space(%{state | string: rest})

  def parse_white_space(state), do: state

  def parse_new_line(
        state = %{
          string: <<char::bytes-size(1)>> <> rest,
          current: current = %{line_number: line_number}
        }
      )
      when char === "\n" or char === "\r\n",
      do: %{state | string: rest, current: %{current | line_number: line_number + 1}}

  def parse_new_line(state), do: {:error, state}

  def parse_right_round_bracket(state = %{string: "(" <> rest}),
    do: put_in(state, [:string], rest)

  def parse_right_round_bracket(state), do: {:error, state}

  def parse_left_round_bracket(state = %{string: ")" <> rest}),
    do: put_in(state, [:string], rest)

  def parse_left_round_bracket(state), do: {:error, state}

  def parse_comma(state = %{string: "," <> rest}), do: put_in(state, [:string], rest)
  def parse_comma(state), do: {:error, state}

  # defp parse_stmt_end(%{
  #        string: <<char::bytes-size(1)>> <> rest,
  #        statements: statements,
  #        result: {:ok, info}
  #      })
  #      when char === ";" or char === "\n" do
  #   statement = {:ok, {length(statements), info}}
  #   %{string: rest, statements: [statement | statements]}
  # end

  # defp parse_stmt_end(state), do: skip_current_statement(state)

  #   alias MipsAssembler.Instruction.R
  #   alias MipsAssembler.Instruction.I
  #   alias MipsAssembler.Instruction.J
  #
  #   def parse(string) do
  #     parse_label(string, [], %{})
  #   end
  #
  #   def parse_label(string, instructions, labels) do
  #     {string, labels} =
  #       case String.split(string, ~r{:}, parts: 2) do
  #         [label, string] ->
  #           {string, update_labels(label, labels, length(instructions))}
  #
  #         [string] ->
  #           {string, labels}
  #       end
  #
  #     parse_op(string, instructions, labels)
  #   end
  #
  #   def parse_op("", instructions, labels), do: {instructions, labels}
  #
  #   def parse_op(<<blank::bytes-size(1)>> <> string, instructions, labels)
  #       when blank == " " or blank == "\t" or blank == "\n" do
  #     parse_op(string, instructions, labels)
  #   end
  #
  #   # def parse_op("add" <> string, instructions, labels),
  #   #   do: parse_other(string, instructions, labels, "add")
  #   def parse_op(string, instructions, labels) do
  #     # IO.inspect(string)
  #
  #     case String.split(string, ~r{\s}, parts: 2) do
  #       [op, string] -> parse_other(string, instructions, labels, op)
  #     end
  #
  #     parse_other(string, instructions, labels, "add")
  #   end
  #
  #   def parse_other(string, instructions, labels, op)
  #       when op === "add" or op === "sub" or op === "addu" or op === "subu" or op === "and" or
  #              op === "or" or op === "nor" or op === "xor" or op === "sllv" or op === "srlv" or
  #              op === "srav" or op === "slt" or op === "sltu" do
  #     {rd, rs, rt, string} =
  #       case String.split(string, ~r{,}, parts: 4) do
  #         [rd, rs, rt, string] ->
  #           {rd, rs, rt, string}
  #
  #         [rd, rs, rt] ->
  #           {rd, rs, rt, ""}
  #
  #         x ->
  #           IO.inspect(["parse_other/4", x])
  #           {"", "", "", String.split(string, ~r{\n}, parts: 2) |> List.last()}
  #       end
  #
  #     # instruction = %{op: op, rd: rd, rs: rs, rt: rt, form: :r}
  #     instruction = R.new(%{op: op, rd: rd, rs: rs, rt: rt})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   def parse_other(string, instructions, labels, op)
  #       when op === "mult" or op === "div" or op === "multu" or op === "divu" do
  #     {rs, rt, string} =
  #       case String.split(string, ~r{,}, parts: 3) do
  #         [rs, rt, string] ->
  #           {rs, rt, string}
  #
  #         [rs, rt] ->
  #           {rs, rt, ""}
  #
  #         _ ->
  #           IO.inspect("error")
  #           {"", "", String.split(string, ~r{\n}, parts: 2) |> List.last()}
  #       end
  #
  #     # instruction = %{op: op, rs: rs, rt: rt, form: :r}
  #     instruction = R.new(%{op: op, rs: rs, rt: rt})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   def parse_other(string, instructions, labels, op)
  #       when op === "sll" or op === "srl" or op === "sra" do
  #     {rd, rt, shamt, string} =
  #       case String.split(string, ~r{,}, parts: 4) do
  #         [rd, rt, shamt, string] ->
  #           {rd, rt, shamt, string}
  #
  #         [rd, rt, shamt] ->
  #           {rd, rt, shamt, ""}
  #
  #         _ ->
  #           IO.inspect("error")
  #           {"", "", "", String.split(string, ~r{\n}, parts: 2) |> List.last()}
  #       end
  #
  #     # instruction = %{op: op, rd: rd, rt: rt, shamt: shamt, form: :r}
  #     instruction = R.new(%{op: op, rd: rd, rt: rt, shamt: shamt})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   def parse_other(string, instructions, labels, op)
  #       when op === "mfhi" or op === "mflo" or op === "mthi" or op === "mtlo" do
  #     {rd, string} =
  #       case String.split(string, ~r{,}, parts: 2) do
  #         [rd, string] ->
  #           {rd, string}
  #
  #         [rd] ->
  #           {rd, ""}
  #
  #         _ ->
  #           IO.inspect("error")
  #           {"", String.split(string, ~r{\n}, parts: 2) |> List.last()}
  #       end
  #
  #     instruction = R.new(%{op: op, rd: rd})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   def parse_other(string, instructions, labels, "jr") do
  #     {rs, string} =
  #       case String.split(string, ~r{,}, parts: 2) do
  #         [rs, string] ->
  #           {rs, string}
  #
  #         [rs] ->
  #           {rs, ""}
  #
  #         _ ->
  #           IO.inspect("error")
  #           {"", String.split(string, ~r{\n}, parts: 2) |> List.last()}
  #       end
  #
  #     instruction = R.new(%{op: "jr", rs: rs})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   def parse_other(string, instructions, labels, "jalr") do
  #     {rs, rd, string} =
  #       case String.split(string, ~r{,}, parts: 3) do
  #         [rs, rd, string] ->
  #           {rs, rd, string}
  #
  #         [rs, rd] ->
  #           {rs, rd, ""}
  #       end
  #
  #     instruction = R.new(%{op: "jalr", rs: rs, rd: rd})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   def parse_other(string, instructions, labels, op)
  #       when op === "addi" or op === "addiu" or op === "andi" or op === "ori" or op === "xori" or
  #              op === "slti" or op === "sltiu" or
  #              op === "beq" or op === "bne" do
  #     {rt, rs, immd, string} =
  #       case String.split(string, ~r{,}, parts: 4) do
  #         [rt, rs, immd, string] ->
  #           {rt, rs, immd, string}
  #
  #         [rt, rs, immd] ->
  #           {rt, rs, immd, ""}
  #       end
  #
  #     instruction = I.new(%{op: op, rt: rt, rs: rs, immd: immd})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   def parse_other(string, instructions, labels, op)
  #       when op === "bgez" or op === "bgtz" or op === "blez" or op === "bltz" do
  #     {rs, offset, string} =
  #       case String.split(string, ~r{,}, parts: 3) do
  #         [rs, offset, string] ->
  #           {rs, offset, string}
  #
  #         [rs, offset] ->
  #           {rs, offset, ""}
  #       end
  #
  #     instruction = I.new(%{op: op, rs: rs, immd: offset})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   def parse_other(string, instructions, labels, op) when op === "lw" or op === "sw" do
  #     {rs, rt, offset, string} =
  #       case String.split(string, ~r{,}, parts: 2) do
  #         [rt, string] ->
  #           case Regex.named_captures(~r{(?<offset>\d*)\((?<rs>.*)\)(?<string>.*)}s, string) do
  #             %{"offset" => offset, "rs" => rs, "string" => string} -> {rs, rt, offset, string}
  #           end
  #       end
  #
  #     # IO.inspect(string)
  #     instruction = I.new(%{op: op, rs: rs, rt: rt, immd: offset})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   def parse_other(string, instructions, labels, op) when op === "j" or op === "jal" do
  #     {address, string} =
  #       case String.split(string, ~r{\n}, parts: 2) do
  #         [address, string] -> {address, string}
  #         [address] -> {address}
  #       end
  #
  #     instruction = J.new(%{op: op, address: address})
  #     parse_label(string, [instruction | instructions], labels)
  #   end
  #
  #   defp update_labels(label, labels, address) do
  #     if Map.has_key?(labels, label) do
  #       %{labels | label => address}
  #     else
  #       IO.inspect("error")
  #       labels
  #     end
  #   end
end
