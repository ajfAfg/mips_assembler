defmodule MipsAssembler.Generator do
  @moduledoc false

  alias MipsAssembler.Instruction.R
  alias MipsAssembler.Instruction.I
  alias MipsAssembler.Instruction.J

  @doc ~S"""
  generate binary

  ## Example
      iex> import MipsAssembler.Generator, only: [generate_binary: 2]
      iex> instructions = [
      ...>   {0, %MipsAssembler.Instruction.R{op: "add", rd: "$t0", rs: "$t1", rt: "$t2", shamt: nil}},
      ...>   {1, %MipsAssembler.Instruction.J{op: "j", address: "foo"}}
      ...> ]
      iex> labels = %{"_start" => 0, "foo" => 1}
      iex> generate_binary(instructions, labels)
      "00000001001010100100000000100000\n00001000000000000000000000000001\n"
  """
  def generate_binary(instructions, labels) do
    # instructions
    # |> Enum.map(&generate(&1, labels))
    binaries = Enum.map(instructions, &generate(&1, labels))

    if Enum.any?(binaries, &(&1 === :error)) do
      :error
    else
      Enum.join(binaries, "\n") <> "\n"
    end
  end

  @doc """
  generate

  ## Example
      iex> alias MipsAssembler.Instruction.R
      iex> alias MipsAssembler.Instruction.I
      iex> alias MipsAssembler.Instruction.J
      iex> import MipsAssembler.Generator, only: [generate: 2]
      iex> {0, R.new(%{op: "sll", rd: "$t0", rt: "$t1", shamt: 1})} |> generate(%{})
      "00000000000010010100000001000000"
      iex> {0, I.new(%{op: "addi", rs: "$t1", rt: "$t0", immd: -1})} |> generate(%{})
      "00100001001010001111111111111111"
      iex> {0, J.new(%{op: "j", address: "foo"})} |> generate(%{"foo" => 1})
      "00001000000000000000000000000001"
  """
  def generate({_address, instruction = %R{}}, _labels) do
    [
      generate_op(instruction),
      generate_rs(instruction),
      generate_rt(instruction),
      generate_rd(instruction),
      generate_shamt(instruction),
      generate_funct(instruction)
    ]
    |> _generate()
  end

  def generate({address, instruction = %I{}}, labels) do
    [
      generate_op(instruction),
      generate_rs(instruction),
      generate_rt(instruction),
      generate_immd(instruction, address, labels)
    ]
    |> _generate()
  end

  def generate({_address, instruction = %J{}}, labels) do
    [
      generate_op(instruction),
      generate_address(instruction, labels)
    ]
    |> _generate()
  end

  defp _generate(binaries) do
    if Enum.any?(binaries, &(&1 === :error)) do
      :error
    else
      binaries
      |> Enum.reverse()
      |> Enum.reduce("", &<>/2)
    end
  end

  @doc """
  op
  """
  def generate_op(%R{}), do: "000000"

  def generate_op(%I{op: "addi"}), do: "001000"
  def generate_op(%I{op: "addiu"}), do: "001001"

  def generate_op(%I{op: "andi"}), do: "001100"
  def generate_op(%I{op: "ori"}), do: "001101"
  def generate_op(%I{op: "xori"}), do: "001110"

  def generate_op(%I{op: "lw"}), do: "100011"
  def generate_op(%I{op: "sw"}), do: "101011"

  def generate_op(%I{op: "slti"}), do: "001010"
  def generate_op(%I{op: "sltiu"}), do: "001011"

  def generate_op(%I{op: "beq"}), do: "000100"
  def generate_op(%I{op: "bne"}), do: "000101"
  def generate_op(%I{op: "bgez"}), do: "000001"
  def generate_op(%I{op: "bgtz"}), do: "000111"
  def generate_op(%I{op: "blez"}), do: "000110"
  def generate_op(%I{op: "bltz"}), do: "000001"

  def generate_op(%J{op: "j"}), do: "000010"
  def generate_op(%J{op: "jal"}), do: "000011"

  def generate_op(_), do: :error

  @doc """
  rs
  """
  def generate_rs(%R{rs: rs}), do: generate_register(rs)
  def generate_rs(%I{rs: rs}), do: generate_register(rs)

  def generate_rs(_), do: :error

  @doc """
  rt
  """
  def generate_rt(%I{op: "bgez"}), do: "00001"
  def generate_rt(%I{op: "bltz"}), do: "00000"

  def generate_rt(%R{rt: rt}), do: generate_register(rt)
  def generate_rt(%I{rt: rt}), do: generate_register(rt)

  def generate_rt(nil), do: "00000"
  def generate_rt(_), do: :error

  @doc """
  rd
  """
  def generate_rd(%R{rd: rd}), do: generate_register(rd)
  def generate_rd(nil), do: "00000"
  def generate_rd(_), do: :error

  @doc """
  shamt
  """
  def generate_shamt(%R{shamt: nil}), do: "00000"
  def generate_shamt(%R{shamt: shamt}), do: convert_binary(shamt, 5)
  def generate_shamt(_), do: :error

  @doc """
  funct
  """
  def generate_funct(%R{op: "add"}), do: "100000"
  def generate_funct(%R{op: "sub"}), do: "100010"
  def generate_funct(%R{op: "mult"}), do: "011000"
  def generate_funct(%R{op: "div"}), do: "011010"

  def generate_funct(%R{op: "addu"}), do: "100001"
  def generate_funct(%R{op: "subu"}), do: "100011"
  def generate_funct(%R{op: "multu"}), do: "011001"
  def generate_funct(%R{op: "divu"}), do: "011011"

  def generate_funct(%R{op: "and"}), do: "100100"
  def generate_funct(%R{op: "or"}), do: "100101"
  def generate_funct(%R{op: "nor"}), do: "100111"
  def generate_funct(%R{op: "xor"}), do: "100110"

  def generate_funct(%R{op: "sll"}), do: "000000"
  def generate_funct(%R{op: "srl"}), do: "000010"
  def generate_funct(%R{op: "sllv"}), do: "000100"
  def generate_funct(%R{op: "srlv"}), do: "000110"
  def generate_funct(%R{op: "sra"}), do: "000011"
  def generate_funct(%R{op: "srav"}), do: "000111"

  def generate_funct(%R{op: "mfhi"}), do: "010000"
  def generate_funct(%R{op: "mflo"}), do: "010010"
  def generate_funct(%R{op: "mthi"}), do: "010001"
  def generate_funct(%R{op: "mtlo"}), do: "010011"

  def generate_funct(%R{op: "slt"}), do: "101010"
  def generate_funct(%R{op: "sltu"}), do: "101011"

  def generate_funct(%R{op: "jr"}), do: "001000"
  def generate_funct(%R{op: "jalr"}), do: "001001"

  def generate_funct(_), do: :error

  @doc """
  immd
  """
  def generate_immd(%I{immd: immd}, address, labels),
    do: generate_label_or_immd(immd, address, labels, 16)

  def generate_immd(_, _, _), do: :error

  @doc """
  address
  """
  def generate_address(%J{address: address}, labels),
    do: generate_label_or_immd(address, 0, labels, 26)

  def generate_address(_, _), do: :error

  @doc """
  register
  """
  def generate_register("$zero"), do: "00000"
  def generate_register("$at"), do: "00001"
  def generate_register("$v0"), do: "00010"
  def generate_register("$v1"), do: "00011"
  def generate_register("$a0"), do: "00100"
  def generate_register("$a1"), do: "00101"
  def generate_register("$a2"), do: "00110"
  def generate_register("$a3"), do: "00111"
  def generate_register("$t0"), do: "01000"
  def generate_register("$t1"), do: "01001"
  def generate_register("$t2"), do: "01010"
  def generate_register("$t3"), do: "01011"
  def generate_register("$t4"), do: "01100"
  def generate_register("$t5"), do: "01101"
  def generate_register("$t6"), do: "01110"
  def generate_register("$t7"), do: "01111"
  def generate_register("$t8"), do: "11000"
  def generate_register("$t9"), do: "11001"
  def generate_register("$s0"), do: "10000"
  def generate_register("$s1"), do: "10001"
  def generate_register("$s2"), do: "10010"
  def generate_register("$s3"), do: "10011"
  def generate_register("$s4"), do: "10100"
  def generate_register("$s5"), do: "10101"
  def generate_register("$s6"), do: "10110"
  def generate_register("$s7"), do: "10111"
  def generate_register("$k0"), do: "11010"
  def generate_register("$k1"), do: "11011"
  def generate_register("$gp"), do: "11100"
  def generate_register("$sp"), do: "11101"
  def generate_register("$fp"), do: "11110"
  def generate_register("$ra"), do: "11111"
  def generate_register(nil), do: "00000"
  def generate_register(_), do: :error

  def generate_label(label, base_address, labels, size) do
    case Map.get(labels, label) do
      nil -> :error
      address -> convert_binary(address - base_address, size)
    end
  end

  defp convert_binary(number, size) when is_integer(number) and is_integer(size) do
    ceil = :math.pow(2, size) |> round()

    rem(ceil + number, ceil)
    |> Integer.to_string(2)
    |> String.pad_leading(size, "0")
  end

  defp convert_binary(_, _), do: :error

  defp generate_label_or_immd(value, base_address, labels, size) do
    case {generate_label(value, base_address, labels, size), convert_binary(value, size)} do
      {:error, :error} -> :error
      {:error, immd_bin} -> immd_bin
      {label_bin, _} -> label_bin
    end
  end
end
