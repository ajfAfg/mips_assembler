defmodule MipsAssembler.Converter do
  @r %{op: nil, rd: nil, rs: nil, rt: nil, shamt: nil}
  @i %{op: nil, rs: nil, rt: nil, immd: nil}
  @j %{op: nil, address: nil}

  @moduledoc """
  converter
  """

  alias MipsAssembler.Instruction.R
  alias MipsAssembler.Instruction.I
  alias MipsAssembler.Instruction.J

  @doc """
  convert

  ## Example
      iex> import MipsAssembler.Converter, only: [convert: 1]
      iex> statements = [
      ...>   {:ok, {1, %{label: "_start", instruction: {}}}},
      ...>   {:ok, {2, %{label: "", instruction: {"add", "$t0", "$t1", "$t2"}}}},
      ...>   {:ok, {3, %{label: "foo", instruction: {"j", "foo"}}}}
      ...> ]
      iex> convert(statements)
      {
        %{"_start" => 0, "foo" => 1},
        [
          {0, %MipsAssembler.Instruction.R{op: "add", rd: "$t0", rs: "$t1", rt: "$t2", shamt: nil}},
          {1, %MipsAssembler.Instruction.J{op: "j", address: "foo"}}
        ]
      }
  """
  def convert(statements) do
    statements
    |> Enum.map(fn {:ok, {_line_number, element}} -> element end)
    |> Enum.reduce({%{}, []}, fn element, acc -> convert_label_and_instruction(element, acc) end)
    |> Kernel.then(fn {labels, instructions} -> {labels, Enum.reverse(instructions)} end)

    # |> divide_label_and_instruction()
  end

  @doc """
  convert label and instruction

  ## Example
      iex> import MipsAssembler.Converter, only: [convert_label_and_instruction: 2]
      iex> convert_label_and_instruction(%{label: "", instruction: {}}, {%{}, []})
      {%{}, []}
      iex> convert_label_and_instruction(%{label: "foo", instruction: {}}, {%{}, []})
      {%{"foo" => 0}, []}
      iex> convert_label_and_instruction(%{label: "", instruction: {"j", "foo"}}, {%{}, []})
      {%{}, [{0, %MipsAssembler.Instruction.J{op: "j", address: "foo"}}]}
      iex> convert_label_and_instruction(%{label: "foo", instruction: {"j", "foo"}}, {%{}, []})
      {%{"foo" => 0}, [{0, %MipsAssembler.Instruction.J{op: "j", address: "foo"}}]}
  """
  def convert_label_and_instruction(%{label: "", instruction: {}}, acc), do: acc

  def convert_label_and_instruction(%{label: label, instruction: {}}, {labels, instructions}),
    do: {append_label(labels, label, length(instructions)), instructions}

  def convert_label_and_instruction(
        %{label: "", instruction: instruction},
        {labels, instructions}
      ),
      do: {labels, [{length(instructions), convert_instruction(instruction)} | instructions]}

  def convert_label_and_instruction(
        %{label: label, instruction: instruction},
        {labels, instructions}
      ),
      do:
        {append_label(labels, label, length(instructions)),
         [{length(instructions), convert_instruction(instruction)} | instructions]}

  @doc """
  append label

  ## Example
      iex> import MipsAssembler.Converter, only: [append_label: 3]
      iex> append_label(%{}, "_foo", 0)
      %{"_foo" => 0}
      iex> append_label(%{"_foo" => 0}, "_foo", 1)
      %{"_foo" => :error}
  """
  def append_label(labels, label, address) do
    value =
      if Map.has_key?(labels, label) do
        :error
      else
        address
      end

    put_in(labels, [label], value)
  end

  @doc """
  convert instruction

  ## Example
      iex> import MipsAssembler.Converter, only: [convert_instruction: 1]
      iex> convert_instruction({"addi", "$t0", "$t1", "-1"})
      %MipsAssembler.Instruction.I{
        op: "addi",
        rs: "$t1",
        rt: "$t0",
        immd: -1
      }
  """
  def convert_instruction({op, rd, rs, rt})
      when op === "add" or op === "sub" or op === "addu" or op === "subu" or op === "and" or
             op === "or" or op === "nor" or op === "xor" or op === "slt" or op === "sltu",
      do: R.new(%{@r | op: op, rd: rd, rs: rs, rt: rt})

  def convert_instruction({op, rd, rt, shamt})
      when op === "sll" or op === "srl" or op === "sra",
      do: R.new(%{@r | op: op, rd: rd, rt: rt, shamt: to_integer_if_needed(shamt)})

  def convert_instruction({op, rd, rt, rs}) when op === "sllv" or op === "srlv",
    do: R.new(%{@r | op: op, rd: rd, rs: rs, rt: rt})

  def convert_instruction({op, rs, rt})
      when op === "mult" or op === "div" or op === "multu" or op === "divu",
      do: R.new(%{@r | op: op, rs: rs, rt: rt})

  def convert_instruction({op = "jalr", rs, rd}), do: R.new(%{@r | op: op, rs: rs, rd: rd})

  def convert_instruction({op, rd})
      when op === "mfhi" or op === "mflo" or op === "mthi" or op === "mtlo",
      do: R.new(%{@r | op: op, rd: rd})

  def convert_instruction({op = "jr", rs}), do: R.new(%{@r | op: op, rs: rs})

  def convert_instruction({op, rt, rs, immd})
      when op === "addi" or op === "addiu" or op === "andi" or op === "ori" or op === "xori" or
             op === "slti" or op === "sltiu",
      do: I.new(%{@i | op: op, rt: rt, rs: rs, immd: to_integer_if_needed(immd)})

  def convert_instruction({op, rs, rt, immd}) when op === "beq" or op === "bne",
    do: I.new(%{@i | op: op, rs: rs, rt: rt, immd: to_integer_if_needed(immd)})

  def convert_instruction({op, rt, immd, rs}) when op === "lw" or op === "sw",
    do: I.new(%{@i | op: op, rt: rt, immd: to_integer_if_needed(immd), rs: rs})

  def convert_instruction({op, address}) when op === "j" or op === "jal",
    do: J.new(%{@j | op: op, address: to_integer_if_needed(address)})

  def convert_instruction(_), do: :error

  defp to_integer_if_needed(string_number) do
    try do
      string_number
      |> String.replace(" ", "")
      |> String.to_integer()
    rescue
      _ -> string_number
    end
  end
end
