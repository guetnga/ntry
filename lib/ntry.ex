defmodule Ntry do
  alias Ntry.{Backoff, Context, Policy}

  defmacro retry(func, opts, do: clauses) do
    {context, opts} =
      if is_list(opts) do
        Keyword.pop(opts, :context, Macro.var(:_context, __MODULE__))
      else
        {Macro.var(:_context, __MODULE__), opts}
      end

    quote do
      Ntry.run(
        unquote(func),
        fn result, unquote(context) ->
          case result do
            unquote(clauses)
          end
        end,
        unquote(opts)
      )
    end
  end

  def run(func, handler, opts) do
    case Policy.from_opts(opts) do
      {:ok, policy} ->
        do_run(func, handler, Backoff.backoff(policy), Context.new(policy))

      {:error, :invalid_policy} = error ->
        error
    end
  end

  defp do_run(func, handler, delays, context) do
    {result, decision} =
      try do
        result = if is_function(func, 1), do: func.(context), else: func.()

        decision =
          if is_function(handler, 2), do: handler.(result, context), else: handler.(result)

        {result, decision}
      catch
        kind, reason ->
          :erlang.raise(kind, reason, __STACKTRACE__)
      end

    case decision do
      :halt ->
        result

      {:halt, value} ->
        value

      :retry ->
        schedule_next(func, handler, delays, context, result, nil)

      {:retry, delay} when delay >= 0 ->
        schedule_next(func, handler, delays, context, result, delay)

      other ->
        raise ArgumentError, "invalid retry decision: #{inspect(other)}"
    end
  end

  defp schedule_next(_func, _handler, _delays, context, result, _override)
       when context.attempt == context.max_attempts,
       do: result

  defp schedule_next(func, handler, delays, context, result, override) do
    case Backoff.next(delays) do
      {:ok, delay, cursor} ->
        try do
          Process.sleep(override || delay)
        catch
          kind, reason ->
            :erlang.raise(kind, reason, __STACKTRACE__)
        end

        do_run(func, handler, cursor, %{
          context
          | attempt: context.attempt + 1,
            last_result: result
        })

      :done ->
        result
    end
  end
end
