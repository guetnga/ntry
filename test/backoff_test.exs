defmodule NtryBackoffTest do
  use ExUnit.Case, async: true

  alias Ntry.Backoff
  alias Ntry.Policy

  describe "backoff/1" do
    test "fixed strategy" do
      policy = %Policy{strategy: :fixed, delay: 1000, max_attempts: 6}
      delays = Backoff.backoff(policy) |> Enum.to_list()
      assert delays == [1000, 1000, 1000, 1000, 1000]
    end

    test "linear strategy" do
      policy = %Policy{strategy: :linear, base_delay: 500, max_attempts: 6}
      delays = Backoff.backoff(policy) |> Enum.to_list()
      assert delays == [500, 1000, 1500, 2000, 2500]
    end

    test "exponential strategy" do
      policy = %Policy{strategy: :exponential, base_delay: 500, max_attempts: 6}
      delays = Backoff.backoff(policy) |> Enum.to_list()
      assert delays == [500, 1000, 2000, 4000, 8000]
    end

    test "max_delay is respected" do
      policy = %Policy{strategy: :exponential, base_delay: 500, max_delay: 3000, max_attempts: 6}
      delays = Backoff.backoff(policy) |> Enum.to_list()
      assert delays == [500, 1000, 2000, 3000, 3000]
    end

    test "max_attempts of 1 results in empty stream" do
      policy = %Policy{strategy: :fixed, delay: 1000, max_attempts: 1}
      delays = Backoff.backoff(policy) |> Enum.to_list()
      assert delays == []
    end
  end

  describe "next/1" do
    test "returns next delay and continuation for stream" do
      policy = %Policy{strategy: :linear, base_delay: 500, max_attempts: 3}
      delays = Backoff.backoff(policy)

      {:ok, delay, delays} = Backoff.next(delays)
      assert delay == 500

      {:ok, delay, _} = Backoff.next(delays)
      assert delay == 1000
    end

    test "returns :done when stream is exhausted" do
      policy = %Policy{strategy: :fixed, delay: 1000, max_attempts: 2}
      stream = Backoff.backoff(policy)
      {:ok, _delay, delays} = Backoff.next(stream)
      assert Backoff.next(delays) == :done
    end
  end

  describe "backoff boundary" do
    test "one attempt has no pauses for all strategies" do
      for strategy <- [:fixed, :linear, :exponential] do
        assert Backoff.backoff(%Policy{strategy: strategy, max_attempts: 1}) |> Enum.to_list() ==
                 []
      end
    end

    test "infinite backoff is lazy and contains capped integers" do
      stream =
        Backoff.backoff(%Policy{
          strategy: :exponential,
          base_delay: 3,
          max_delay: 10,
          max_attempts: :infinity
        })

      assert Enum.take(stream, 5) === [3, 6, 10, 10, 10]
    end

    test "cursor closes an active resource" do
      owner = self()

      stream =
        Stream.resource(fn -> 0 end, fn n -> {[n], n + 1} end, fn _ -> send(owner, :closed) end)

      {:ok, 0, cursor} = Backoff.next(stream)
      refute_received :closed
      assert Backoff.close(cursor) == :done
      assert_received :closed
    end
  end
end
