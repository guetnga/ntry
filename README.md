# Ntry

Ntry is a small Elixir library for running operations with configurable retries and backoff.

## Installation

Add `ntry` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ntry, "~> 0.1.0"}
  ]
end
```

## Usage

`Ntry.retry/3` accepts an operation function, a retry policy, and clauses that decide what to do
with each result:

```elixir
require Ntry

Ntry.retry fn -> request() end,
  max_attempts: 3,
  delay: 500 do
  {:ok, value} -> {:halt, value}
  {:error, :timeout} -> :retry
  {:error, reason} -> {:halt, {:error, reason}}
end
```

The operation may accept a retry context. Use the `:context` option to bind the same context in
the result clauses:

```elixir
Ntry.retry fn context -> request(context.attempt) end,
  max_attempts: 3,
  delay: 500,
  context: context,
  metadata: %{service: :payments} do
  {:ok, value} -> {:halt, value}
  {:error, :timeout} when context.attempt < context.max_attempts -> :retry
  result -> {:halt, result}
end
```

`Ntry.Context` contains:

- `attempt` – the current attempt number, starting at `1`.
- `max_attempts` – the configured maximum number of attempts.
- `last_result` – the result of the previous attempt, or `nil` on the first attempt.
- `metadata` – the map supplied through the policy's `:metadata` option.

## Function API

`Ntry.run/3` accepts an operation, a result handler, and a retry policy:

```elixir
Ntry.run(
  fn context -> request(context.attempt) end,
  fn
    {:ok, value}, _context -> {:halt, value}
    {:error, :timeout}, _context -> :retry
    result, _context -> {:halt, result}
  end,
  max_attempts: 3,
  strategy: :exponential,
  base_delay: 100,
  max_delay: 2_000
)
```

The operation may have arity zero or one. An arity-one operation receives `Ntry.Context`.
The handler may have arity one or two. An arity-two handler receives the result and the context.

The handler must return one of the following decisions:

- `:halt` – stop and return the operation's result.
- `{:halt, value}` – stop and return `value`.
- `:retry` – retry using the delay from the configured backoff strategy.
- `{:retry, delay}` – retry after `delay` milliseconds instead of the configured delay.

If the handler requests a retry after the final attempt, Ntry returns the final operation result.
Exceptions, exits, and thrown values from the operation or handler are propagated to the caller.

## Policies

Available options:

- `max_attempts` – total number of attempts; defaults to `3`. May be `:infinity`.
- `strategy` – `:fixed`, `:linear`, or `:exponential`; defaults to `:fixed`.
- `delay` – delay in milliseconds for the fixed strategy; defaults to `1000`.
- `base_delay` – initial delay for linear and exponential strategies; defaults to `1000`.
- `max_delay` – maximum delay for linear and exponential strategies; defaults to `:infinity`.
- `metadata` – a map made available through `Ntry.Context`; defaults to `%{}`.

A reusable policy can be supplied through `:with`. Options specified alongside it take
precedence:

```elixir
@policy [
  max_attempts: 3,
  strategy: :exponential,
  base_delay: 100,
  max_delay: 2_000
]

Ntry.retry fn -> request() end,
  with: @policy,
  max_attempts: 5 do
  {:ok, value} -> {:halt, value}
  {:error, :timeout} -> :retry
  result -> {:halt, result}
end
```
