defmodule CtxServer.Macro do
  defmacro defdelegate_module(mod) do
    {mod, _} = Code.eval_quoted(mod)
    functions = mod.__info__(:functions)
    for {name, arity} <- functions do
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
end
