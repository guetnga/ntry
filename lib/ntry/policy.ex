defmodule Ntry.Policy do
  defstruct max_attempts: 3,
            delay: 1000,
            base_delay: 1000,
            max_delay: :infinity,
            strategy: :fixed,
            jitter: false,
            on_fail: nil,
            metadata: %{}

  def from_opts(opts) do
    with true <- Keyword.keyword?(opts),
         base <- Keyword.get(opts, :with, []),
         true <- Keyword.keyword?(base),
         merged <- Keyword.merge(base, Keyword.delete(opts, :with)),
         true <-
           Enum.all?(Keyword.keys(merged), &(&1 in Map.keys(Map.from_struct(%__MODULE__{})))) do
      policy = struct!(__MODULE__, merged)
      if valid?(policy), do: {:ok, policy}, else: {:error, :invalid_policy}
    else
      _ -> {:error, :invalid_policy}
    end
  end

  defp valid?(policy) do
    valid_max_attempts?(policy.max_attempts) and
      non_negative_integer?(policy.delay) and
      non_negative_integer?(policy.base_delay) and
      valid_max_delay?(policy.max_delay) and
      policy.strategy in [:fixed, :exponential, :linear] and
      is_boolean(policy.jitter) and is_map(policy.metadata) and
      (is_function(policy.on_fail, 1) or is_nil(policy.on_fail))
  end

  defp valid_max_attempts?(:infinity), do: true
  defp valid_max_attempts?(value), do: positive_integer?(value)

  defp valid_max_delay?(:infinity), do: true
  defp valid_max_delay?(value), do: non_negative_integer?(value)

  defp positive_integer?(value), do: is_integer(value) and value > 0
  defp non_negative_integer?(value), do: is_integer(value) and value >= 0
end
