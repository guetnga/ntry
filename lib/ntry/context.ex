defmodule Ntry.Context do
  defstruct [:max_attempts, attempt: 1, last_result: nil, metadata: %{}]

  def new(%Ntry.Policy{} = policy) do
    %__MODULE__{max_attempts: policy.max_attempts, metadata: policy.metadata}
  end
end
