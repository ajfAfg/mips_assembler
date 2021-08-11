defmodule MipsAssembler.Converter do
  @r %{op: "", rd: "", rs: "", rt: "", shamt: ""}
  @i %{op: "", rs: "", rt: "", immd: ""}
  @j %{op: "", address: ""}

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
          %MipsAssembler.Instruction.R{op: "add", rd: "$t0", rs: "$t1", rt: "$t2", shamt: ""},
          %MipsAssembler.Instruction.J{op: "j", address: "foo"}
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
      {%{}, [%MipsAssembler.Instruction.J{op: "j", address: "foo"}]}
      iex> convert_label_and_instruction(%{label: "foo", instruction: {"j", "foo"}}, {%{}, []})
      {%{"foo" => 0}, [%MipsAssembler.Instruction.J{op: "j", address: "foo"}]}
  """
  def convert_label_and_instruction(%{label: "", instruction: {}}, acc), do: acc

  def convert_label_and_instruction(%{label: label, instruction: {}}, {labels, instructions}),
    do: {append_label(labels, label, length(instructions)), instructions}

  def convert_label_and_instruction(
        %{label: "", instruction: instruction},
        {labels, instructions}
      ),
      do: {labels, [convert_instruction(instruction) | instructions]}

  def convert_label_and_instruction(
        %{label: label, instruction: instruction},
        {labels, instructions}
      ),
      do:
        {append_label(labels, label, length(instructions)),
         [convert_instruction(instruction) | instructions]}

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
      iex> convert_instruction({"add", "$t0", "$t1", "$t2"})
      %MipsAssembler.Instruction.R{
        op: "add",
        rd: "$t0",
        rs: "$t1",
        rt: "$t2",
        shamt: ""
      }
  """
  def convert_instruction({op, rd, rs, rt})
      when op === "add" or op === "sub" or op === "addu" or op === "subu" or op === "and" or
             op === "or" or op === "nor" or op === "xor" or op === "slt" or op === "sltu",
      do: R.new(%{@r | op: op, rd: rd, rs: rs, rt: rt})

  def convert_instruction({op, rd, rt, shamt})
      when op === "sll" or op === "srl" or op === "sra",
      do: R.new(%{@r | op: op, rd: rd, rt: rt, shamt: shamt})

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
      do: I.new(%{@i | op: op, rt: rt, rs: rs, immd: immd})

  def convert_instruction({op, rs, rt, immd}) when op === "beq" or op === "bne",
    do: I.new(%{@i | op: op, rs: rs, rt: rt, immd: immd})

  def convert_instruction({op, rt, immd, rs}) when op === "lw" or op === "sw",
    do: I.new(%{@i | op: op, rt: rt, immd: immd, rs: rs})

  def convert_instruction({op, address}) when op === "j" or op === "jal",
    do: J.new(%{@j | op: op, address: address})

  def convert_instruction(_), do: :error

  #   def divide_label_and_instruction(elements) do
  #     labels =
  #       elements
  #       |> Enum.map(fn %{label: label} -> label end)
  #       |> Enum.map(fn label -> label !== "" end)
  #
  #     operands =
  #       elements
  #       |> Enum.map(fn %{operand: operand} -> operand end)
  #       |> Enum.filter(fn operand -> operand !== {} end)
  #
  #     {labels, operands}
  #   end
end
