defmodule Ntry.Backoff do
  def backoff(policy) do
    initial = if policy.strategy == :fixed, do: policy.delay, else: policy.base_delay

    remaining = if policy.max_attempts == :infinity, do: :infinity, else: policy.max_attempts - 1

    Stream.unfold({initial, remaining}, fn
      {_delay, 0} ->
        nil

      {delay, remaining} ->
        capped = if policy.strategy == :fixed, do: delay, else: cap(delay, policy.max_delay)

        next =
          case policy.strategy do
            :fixed -> capped
            :linear -> cap(capped + policy.base_delay, policy.max_delay)
            :exponential -> cap(capped * 2, policy.max_delay)
          end

        remaining = if remaining == :infinity, do: :infinity, else: remaining - 1
        {capped, {next, remaining}}
    end)
  end

  def next({:cursor, continuation}) do
    continuation.({:cont, nil})
    |> next_delay()
  end

  def next(stream) do
    Enumerable.reduce(stream, {:cont, nil}, fn delay, _acc ->
      {:suspend, delay}
    end)
    |> next_delay()
  end

  def close({:cursor, continuation}) do
    continuation.({:halt, nil})
    :done
  end

  def close(_stream), do: :done

  defp cap(delay, :infinity), do: delay
  defp cap(delay, max_delay), do: min(delay, max_delay)

  defp next_delay({:suspended, delay, continuation}) do
    {:ok, delay, {:cursor, continuation}}
  end

  defp next_delay({:done, _acc}) do
    :done
  end
end
