# Ntry

Ntry is small Elixir library for implementing retries with
configurable backoff.

## Usage

```elixir
@policy max_attempts: 3,
        delay: 500,
        on: [{:error, :timeout}]

Ntry.retry with: @policy do
  request()
end

# Or inline

Ntry.retry max_attempts: 3,
           delay: 500,
           on: [{:error, :timeout}] do
  request()
end
```

The function form accepts a zero-arity function:

```elixir
Ntry.run(fn -> request() end,
  max_attempts: 3,
  strategy: :exponential,
  base_delay: 100,
  max_delay: 2_000,
  on: [{:error, :timeout}]
)
```

Available options:

- `max_attempts` – total number of attempts; defaults to `3`.
- `strategy` – `:fixed`, `:linear`, or `:exponential`; defaults to `:fixed`.
- `delay` – delay in milliseconds for the fixed strategy; defaults to `1000`.
- `base_delay` – initial delay for linear and exponential strategies; defaults to `1000`.
- `max_delay` – maximum delay for linear and exponential strategies; defaults to `:infinity`.
- `on` – return values that should trigger another attempt; defaults to `[{:error, :timeout}]`.

Ntry returns the first non-retryable result, or the result of the final attempt.

## Installation

Add `ntry` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ntry, "~> 0.1.0"}
  ]
end
```

