defmodule MipsAssembler.Instruction.Helper do
  @moduledoc """
  helper
  """

  def get(map, key) do
    Map.get(map, key, "")
    # |> String.replace(~r{[a-z /]}, "")
    # |> :string.trim()
    |> trim_if_needed()
  end

  defp trim_if_needed(element) when is_atom(element), do: element
  defp trim_if_needed(element), do: String.trim(element)
end
