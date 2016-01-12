defmodule CtxServer.Macro do
  defmacro context(contexts, do: block) do
    elem Macro.prewalk(block, contexts, &modify_handers_ast/2), 0
  end

  defp modify_handers_ast({:def, meta1, [{name, meta2, args}, [do: body]]}, contexts)
  when name == :handle_call and length(args) == 3 or
       name == :handle_cast and length(args) == 2 do
    new_ast = modify_args({:def, meta1, [{name, meta2, args}, [do: body]]}, contexts)
    {new_ast, contexts}
  end

  defp modify_handers_ast(ast, contexts) do
    {ast, contexts}
  end

  defp modify_args({:def, meta1, [{function_name, meta2, args}, [do: body]]}, contexts) do
    new_args = args ++ [Macro.escape(Enum.into(contexts, %{}))]
    {:def, meta1, [{function_name, meta2, new_args}, [do: body]]}
  end


  defmacro defdelegate_module(mod, opt) do
    except = opt[:except] || []
    {mod, _} = Code.eval_quoted(mod)

    for {name, arity} <- mod.__info__(:functions),
        !Enum.member?(except, {name, arity}) do
      defdelegate_ast(mod, name, arity)
    end
  end

  defp defdelegate_ast(mod, name, 1) do
    quote do
      defdelegate unquote(name)(arg1), to: unquote(mod)
    end
  end

  defp defdelegate_ast(mod, name, 2) do
    quote do
      defdelegate unquote(name)(arg1, arg2), to: unquote(mod)
    end
  end

  defp defdelegate_ast(mod, name, 3) do
    quote do
      defdelegate unquote(name)(arg1, arg2, arg3), to: unquote(mod)
    end
  end

  defp defdelegate_ast(mod, name, 4) do
    quote do
      defdelegate unquote(name)(arg1, arg2, arg3, arg4), to: unquote(mod)
    end
  end


  defmacro rescue_with_tuple(do: expr) do
    quote do
      try do
        unquote(expr)
      rescue
        e -> {'EXIT', Exception.message(e)}
      end
    end
  end
end
