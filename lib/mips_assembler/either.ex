defmodule MipsAssembler.Either do
  @moduledoc """
  This is a module like Either type.
  """

  def ok(v), do: {:ok, v}
  def error(v), do: {:error, v}

  def chain({:ok, v}, f), do: f.(v)
  def chain(err = {:error, _v}, _f), do: err
end
