defmodule Ntry do
  defmacro retry(opts, do: block) do
    quote do
      Ntry.run(fn -> unquote(block) end, unquote(opts))
    end
  end

  def run(func, opts) do
    case Ntry.Policy.from_opts(opts) do
      {:ok, policy} ->
        config = %Ntry.Config{
          func: func,
          delays: build_delays(policy),
          retryable?: fn result -> Enum.any?(policy.on, &(&1 == result)) end
        }

        do_run(config)

      {:error, :invalid_policy} ->
        {:error, :invalid_policy}
    end
  end

  def build_delays(policy) do
    case policy.strategy do
      :fixed ->
        List.duplicate(policy.delay, policy.max_attempts - 1)

      :linear ->
        Enum.map(1..(policy.max_attempts - 1), fn i ->
          min(policy.base_delay * i, policy.max_delay)
        end)

      :exponential ->
        Enum.map(0..(policy.max_attempts - 2), fn i ->
          min(policy.base_delay * 2 ** i, policy.max_delay)
        end)
    end
  end

  defp do_run(%{func: func, delays: []}, _state) do
    func.()
  end

  defp do_run(
         %{func: func, delays: [delay | rest], retryable?: retryable?} = config,
         %{attempt: attempt} = state
       ) do
    result = func.()

    if retryable?.(result) do
      Process.sleep(delay)
      do_run(%{config | delays: rest}, %{state | attempt: attempt + 1, last_result: result})
    else
      result
    end
  end

  defp do_run(config) do
    do_run(config, Ntry.State.new())
  end
end
