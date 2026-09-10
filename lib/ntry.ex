defmodule Ntry do
  alias Ntry.{Backoff, Context, Policy}

  defmacro retry(func, opts, do: clauses) do
    {context, opts} = define_context(opts)

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

  defmacro retry(func, opts, do: clauses, else: on_fail) do
    {context, opts} = define_context(opts)

    quote do
      Ntry.run(
        unquote(func),
        fn result, unquote(context) ->
          case result do
            unquote(clauses)
          end
        end,
        Keyword.merge(unquote(opts), on_fail: fn unquote(context) -> unquote(on_fail) end)
      )
    end
  end

  defp define_context(opts) do
    if is_list(opts) do
      Keyword.pop(opts, :context, Macro.var(:_context, __MODULE__))
    else
      {Macro.var(:_context, __MODULE__), opts}
    end
  end

  def run(func, handler, opts) do
    case Policy.from_opts(opts) do
      {:ok, policy} ->
        do_run(
          func,
          handler,
          Backoff.backoff(policy),
          Context.new(policy),
          Keyword.get(opts, :on_fail, nil)
        )

      {:error, :invalid_policy} = error ->
        error
    end
  end

  defp do_run(func, handler, delays, context, on_fail) do
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
        schedule_next(func, handler, delays, context, result, nil, on_fail)

      {:retry, delay} when is_integer(delay) and delay >= 0 ->
        schedule_next(func, handler, delays, context, result, delay, on_fail)

      other ->
        raise ArgumentError, "invalid retry decision: #{inspect(other)}"
    end
  end

  defp schedule_next(_func, _handler, _delays, context, result, _override, on_fail)
       when context.attempt == context.max_attempts do
    context = %{context | last_result: result}
    if on_fail, do: on_fail.(context), else: context.last_result
  end

  defp schedule_next(func, handler, delays, context, result, override, on_fail) do
    case Backoff.next(delays) do
      {:ok, delay, cursor} ->
        try do
          Process.sleep(override || delay)
        catch
          kind, reason ->
            :erlang.raise(kind, reason, __STACKTRACE__)
        end

        do_run(
          func,
          handler,
          cursor,
          %{
            context
            | attempt: context.attempt + 1,
              last_result: result
          },
          on_fail
        )

      :done ->
        result
    end
  end
end
