defmodule Ntry.Context do
  @moduledoc "Holds state for the current retry attempt."

  defstruct [:max_attempts, attempt: 1, last_result: nil, metadata: %{}]

  @doc "Builds the initial context for a retry policy."
  def new(%Ntry.Policy{} = policy) do
    %__MODULE__{max_attempts: policy.max_attempts, metadata: policy.metadata}
  end
end
