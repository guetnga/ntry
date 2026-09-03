defmodule NtryTest do
  use ExUnit.Case
  doctest Ntry

  test "after all attempts result is equal to last function result" do
    result =
      Ntry.retry max_attempts: 3, delay: 100 do
        {:error, :timeout}
      end

    assert result == {:error, :timeout}
  end

  test "exponential delays builds correctly" do
    {:ok, policy} =
      Ntry.Policy.from_opts(base_delay: 1000, max_attempts: 4, strategy: :exponential)

    assert Ntry.build_delays(policy) == [1000, 2000, 4000]
  end

  test "linear delays builds correctly" do
    {:ok, policy} = Ntry.Policy.from_opts(base_delay: 1000, max_attempts: 4, strategy: :linear)

    assert Ntry.build_delays(policy) == [1000, 2000, 3000]
  end
end
