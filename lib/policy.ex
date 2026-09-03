defmodule Ntry.Policy do
  defstruct [
    :max_attempts,
    :delay,
    :base_delay,
    :max_delay,
    :strategy,
    :jitter,
    :on
  ]

  def from_opts(opts) do
    opts = Keyword.get(opts, :with, opts)

    policy = %__MODULE__{
      max_attempts: Keyword.get(opts, :max_attempts, 3),
      delay: Keyword.get(opts, :delay, 1000),
      base_delay: Keyword.get(opts, :base_delay, 1000),
      max_delay: Keyword.get(opts, :max_delay, :infinity),
      strategy: Keyword.get(opts, :strategy, :fixed),
      jitter: Keyword.get(opts, :jitter, false),
      on: Keyword.get(opts, :on, [{:error, :timeout}])
    }

    if valid?(policy),
      do: {:ok, policy},
      else: {:error, :invalid_policy}
  end

  defp valid?(policy) do
    (policy.max_attempts > 0 || policy.max_attempts == :infinity) &&
      policy.delay > 0 &&
      policy.base_delay > 0 &&
      (policy.max_delay > 0 || policy.max_delay == :infinity) &&
      Enum.any?([:fixed, :exponential, :linear], fn strategy -> strategy == policy.strategy end) &&
      is_boolean(policy.jitter) &&
      is_list(policy.on)
  end
end
