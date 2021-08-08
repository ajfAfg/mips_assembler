defmodule MipsAssembler.Parser do
  @moduledoc """
  ok
  """

  alias MipsAssembler.Instruction.R
  alias MipsAssembler.Instruction.I
  alias MipsAssembler.Instruction.J

  def parse(string) do
    parse_label(string, [], %{})
  end

  def parse_label(string, instructions, labels) do
    {string, labels} =
      case String.split(string, ~r{:}, parts: 2) do
        [label, string] ->
          {string, update_labels(label, labels, length(instructions))}

        [string] ->
          {string, labels}
      end

    parse_op(string, instructions, labels)
  end

  def parse_op("", instructions, labels), do: {instructions, labels}

  def parse_op(<<blank::bytes-size(1)>> <> string, instructions, labels)
      when blank == " " or blank == "\t" or blank == "\n" do
    parse_op(string, instructions, labels)
  end

  # def parse_op("add" <> string, instructions, labels),
  #   do: parse_other(string, instructions, labels, "add")
  def parse_op(string, instructions, labels) do
    # IO.inspect(string)

    case String.split(string, ~r{\s}, parts: 2) do
      [op, string] -> parse_other(string, instructions, labels, op)
    end

    parse_other(string, instructions, labels, "add")
  end

  def parse_other(string, instructions, labels, op)
      when op === "add" or op === "sub" or op === "addu" or op === "subu" or op === "and" or
             op === "or" or op === "nor" or op === "xor" or op === "sllv" or op === "srlv" or
             op === "srav" or op === "slt" or op === "sltu" do
    {rd, rs, rt, string} =
      case String.split(string, ~r{,}, parts: 4) do
        [rd, rs, rt, string] ->
          {rd, rs, rt, string}

        [rd, rs, rt] ->
          {rd, rs, rt, ""}

        x ->
          IO.inspect(["parse_other/4", x])
          {"", "", "", String.split(string, ~r{\n}, parts: 2) |> List.last()}
      end

    # instruction = %{op: op, rd: rd, rs: rs, rt: rt, form: :r}
    instruction = R.new(%{op: op, rd: rd, rs: rs, rt: rt})
    parse_label(string, [instruction | instructions], labels)
  end

  def parse_other(string, instructions, labels, op)
      when op === "mult" or op === "div" or op === "multu" or op === "divu" do
    {rs, rt, string} =
      case String.split(string, ~r{,}, parts: 3) do
        [rs, rt, string] ->
          {rs, rt, string}

        [rs, rt] ->
          {rs, rt, ""}

        _ ->
          IO.inspect("error")
          {"", "", String.split(string, ~r{\n}, parts: 2) |> List.last()}
      end

    # instruction = %{op: op, rs: rs, rt: rt, form: :r}
    instruction = R.new(%{op: op, rs: rs, rt: rt})
    parse_label(string, [instruction | instructions], labels)
  end

  def parse_other(string, instructions, labels, op)
      when op === "sll" or op === "srl" or op === "sra" do
    {rd, rt, shamt, string} =
      case String.split(string, ~r{,}, parts: 4) do
        [rd, rt, shamt, string] ->
          {rd, rt, shamt, string}

        [rd, rt, shamt] ->
          {rd, rt, shamt, ""}

        _ ->
          IO.inspect("error")
          {"", "", "", String.split(string, ~r{\n}, parts: 2) |> List.last()}
      end

    # instruction = %{op: op, rd: rd, rt: rt, shamt: shamt, form: :r}
    instruction = R.new(%{op: op, rd: rd, rt: rt, shamt: shamt})
    parse_label(string, [instruction | instructions], labels)
  end

  def parse_other(string, instructions, labels, op)
      when op === "mfhi" or op === "mflo" or op === "mthi" or op === "mtlo" do
    {rd, string} =
      case String.split(string, ~r{,}, parts: 2) do
        [rd, string] ->
          {rd, string}

        [rd] ->
          {rd, ""}

        _ ->
          IO.inspect("error")
          {"", String.split(string, ~r{\n}, parts: 2) |> List.last()}
      end

    instruction = R.new(%{op: op, rd: rd})
    parse_label(string, [instruction | instructions], labels)
  end

  def parse_other(string, instructions, labels, "jr") do
    {rs, string} =
      case String.split(string, ~r{,}, parts: 2) do
        [rs, string] ->
          {rs, string}

        [rs] ->
          {rs, ""}

        _ ->
          IO.inspect("error")
          {"", String.split(string, ~r{\n}, parts: 2) |> List.last()}
      end

    instruction = R.new(%{op: "jr", rs: rs})
    parse_label(string, [instruction | instructions], labels)
  end

  def parse_other(string, instructions, labels, "jalr") do
    {rs, rd, string} =
      case String.split(string, ~r{,}, parts: 3) do
        [rs, rd, string] ->
          {rs, rd, string}

        [rs, rd] ->
          {rs, rd, ""}
      end

    instruction = R.new(%{op: "jalr", rs: rs, rd: rd})
    parse_label(string, [instruction | instructions], labels)
  end

  def parse_other(string, instructions, labels, op)
      when op === "addi" or op === "addiu" or op === "andi" or op === "ori" or op === "xori" or
             op === "slti" or op === "sltiu" or
             op === "beq" or op === "bne" do
    {rt, rs, immd, string} =
      case String.split(string, ~r{,}, parts: 4) do
        [rt, rs, immd, string] ->
          {rt, rs, immd, string}

        [rt, rs, immd] ->
          {rt, rs, immd, ""}
      end

    instruction = I.new(%{op: op, rt: rt, rs: rs, immd: immd})
    parse_label(string, [instruction | instructions], labels)
  end

  def parse_other(string, instructions, labels, op)
      when op === "bgez" or op === "bgtz" or op === "blez" or op === "bltz" do
    {rs, offset, string} =
      case String.split(string, ~r{,}, parts: 3) do
        [rs, offset, string] ->
          {rs, offset, string}

        [rs, offset] ->
          {rs, offset, ""}
      end

    instruction = I.new(%{op: op, rs: rs, immd: offset})
    parse_label(string, [instruction | instructions], labels)
  end

  def parse_other(string, instructions, labels, op) when op === "lw" or op === "sw" do
    {rs, rt, offset, string} =
      case String.split(string, ~r{,}, parts: 2) do
        [rt, string] ->
          case Regex.named_captures(~r{(?<offset>\d*)\((?<rs>.*)\)(?<string>.*)}s, string) do
            %{"offset" => offset, "rs" => rs, "string" => string} -> {rs, rt, offset, string}
          end
      end

    # IO.inspect(string)
    instruction = I.new(%{op: op, rs: rs, rt: rt, immd: offset})
    parse_label(string, [instruction | instructions], labels)
  end

  def parse_other(string, instructions, labels, op) when op === "j" or op === "jal" do
    {address, string} =
      case String.split(string, ~r{\n}, parts: 2) do
        [address, string] -> {address, string}
        [address] -> {address}
      end

    instruction = J.new(%{op: op, address: address})
    parse_label(string, [instruction | instructions], labels)
  end

  defp update_labels(label, labels, address) do
    if Map.has_key?(labels, label) do
      %{labels | label => address}
    else
      IO.inspect("error")
      labels
    end
  end
end
