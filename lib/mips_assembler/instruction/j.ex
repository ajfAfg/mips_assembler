defmodule MipsAssembler.Instruction.J do
  defstruct op: nil, address: nil

  import MipsAssembler.Instruction.Helper, only: [get: 2]

  @doc """
  ok

  ## Example
      iex> base = %{op: "j", address: "foo"}
      iex> MipsAssembler.Instruction.J.new(base)
      %MipsAssembler.Instruction.J{
        address: "foo",
        op: "j",
      }
  """
  def new(%{op: _} = base) do
    # Structs are extensions built on top of maps that provide *compile-time checks*.
    # So this time I have to write as follows.
    %MipsAssembler.Instruction.J{
      op: get(base, :op),
      address: get(base, :address)
    }
  end
end
