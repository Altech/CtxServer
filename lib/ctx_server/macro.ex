defmodule CtxServer.Macro do
  defmacro context(contexts, do: block) do
    {contexts, mod} = if (contexts == :any) do
      {[], CtxServer.Macro2}
    else
      {contexts, CtxServer.Macro}
    end

    quote do
      if true do # To create lexical scope for def/2
        import Kernel, except: [def: 2]
        import unquote(mod), only: [def: 2]
        @contexts {:"$contexts", Enum.into(unquote(contexts), %{})}
        unquote(block)
      end
    end
  end


  defmacro def({name, line, args}, expr) do
    import CtxServer.Kernel, only: [define: 4]
    call              = {name, line, proxy_args(args)}
    call_with_context = {name, line, List.wrap(args) ++ [quote do: @contexts]}
    def1 = define(:def, call_with_context, expr,  __CALLER__)
    def2 = define(:def, call, proxy_expr(name, proxy_args(args)), __CALLER__)
    sign = {name, length(List.wrap(args))}
    quote do
      unquote(def1)
      unless Enum.member?(@defined_proxies, unquote(sign)) do
        unquote(def2)
        @defined_proxies unquote(sign)
      end
    end
  end

  def proxy_expr(name, args) do
    ast = quote do
      args = unquote(List.wrap(args)) ++ [{:"$contexts", CtxServer.Contexts.current}]
      apply(__MODULE__, unquote(name), args)
    end
    [do: ast]
  end

  def proxy_args(nil), do: nil

  def proxy_args(args) do
    for {_, i} <- Enum.with_index(args) do
      {String.to_atom("arg#{i+1}"), [line: 1], nil}
    end
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
        e -> {:EXIT, Exception.message(e)}
      end
    end
  end
end
