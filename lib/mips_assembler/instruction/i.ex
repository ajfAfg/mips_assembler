defmodule MipsAssembler.Instruction.I do
  defstruct op: "", rs: "", rt: "", immd: ""

  import MipsAssembler.Instruction.Helper, only: [get: 2]

  @doc """
  ok

  ## Example
      iex> base = %{op: "addi", rt: "$t0", rs: "$zero", immd: "1"}
      iex> MipsAssembler.Instruction.I.new(base)
      %MipsAssembler.Instruction.I{
        immd: "1",
        op: "addi",
        rs: "$zero",
        rt: "$t0",
      }
  """
  def new(%{op: _} = base) do
    # Structs are extensions built on top of maps that provide *compile-time checks*.
    # So this time I have to write as follows.
    %MipsAssembler.Instruction.I{
      op: get(base, :op),
      rs: get(base, :rs),
      rt: get(base, :rt),
      immd: get(base, :immd)
    }
  end
end
