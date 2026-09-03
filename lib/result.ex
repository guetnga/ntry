defmodule Ntry.State do
  defstruct [:attempt, :last_result]

  def new(), do: %__MODULE__{attempt: 1, last_result: nil}
end
