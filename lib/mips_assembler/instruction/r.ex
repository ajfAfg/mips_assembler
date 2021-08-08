defmodule MipsAssembler.Instruction.R do
  defstruct op: "", rd: "", rs: "", rt: "", shamt: ""

  import MipsAssembler.Instruction.Helper, only: [get: 2]

  @doc """
  ok

  ## Example
      iex> base = %{op: "add", rd: "$t0", rs: "$zero", rt: "$t1"}
      iex> MipsAssembler.Instruction.R.new(base)
      %MipsAssembler.Instruction.R{
        op: "add",
        rd: "$t0",
        rs: "$zero",
        rt: "$t1",
        shamt: ""
      }
  """
  def new(%{op: _} = base) do
    # Structs are extensions built on top of maps that provide *compile-time checks*.
    # So this time I have to write as follows.
    %MipsAssembler.Instruction.R{
      op: get(base, :op),
      rd: get(base, :rd),
      rs: get(base, :rs),
      rt: get(base, :rt),
      shamt: get(base, :shamt)
    }
  end
end
