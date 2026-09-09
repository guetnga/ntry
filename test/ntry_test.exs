defmodule NtryTest do
  use ExUnit.Case, async: true
  require Ntry

  test "handler runs on every attempt including the last" do
    owner = self()

    assert Ntry.run(
             fn ctx -> {:error, ctx.attempt} end,
             fn result, ctx ->
               send(owner, {ctx.attempt, ctx.last_result, result})
               :retry
             end,
             max_attempts: 3,
             delay: 0
           ) == {:error, 3}

    assert_received {1, nil, {:error, 1}}
    assert_received {2, {:error, 1}, {:error, 2}}
    assert_received {3, {:error, 2}, {:error, 3}}
  end

  test "macro binds context and preserves guards and matched variables" do
    result =
      Ntry.retry fn ctx -> {:ok, ctx.metadata.value} end,
        max_attempts: 1,
        context: ctx,
        metadata: %{value: 42} do
        {:ok, value} when ctx.attempt == 1 -> {:halt, value + 1}
      end

    assert result == 43
  end

  test "zero arity operations and one arity handlers remain supported" do
    assert Ntry.run(fn -> :value end, fn :value -> :halt end, []) == :value
  end

  test "custom delay overrides standard delay" do
    assert Ntry.run(
             fn ctx -> ctx.attempt end,
             fn _ ->
               {:retry, 0}
             end,
             max_attempts: 2,
             delay: 60_000
           ) == 2
  end

  test "ordinary exceptions propagate" do
    assert_raise RuntimeError, "failure", fn ->
      Ntry.run(fn -> raise "failure" end, fn _ -> :halt end, [])
    end
  end

  test "policy overrides and validation" do
    assert {:ok, policy} = Ntry.Policy.from_opts(with: [delay: 500, max_attempts: 3], delay: 0)
    assert policy.delay == 0
    assert policy.max_attempts == 3

    for opts <- [[delay: nil], [max_attempts: :bad], [on: []], [jitter: "true"]] do
      assert Ntry.Policy.from_opts(opts) == {:error, :invalid_policy}
    end
  end
end
