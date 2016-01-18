defmodule CtxServer.Macro do
  defmacro context(contexts, do: block) do
    quote do
      if true do # To create lexical scope for def/2
        import Kernel,        except: [def: 2]
        import CtxServer.Macro, only: [def: 2]
        contexts = for {name, value} <- unquote(contexts), into: %{}, do: {name, value}
        @contexts {:"$contexts", contexts}
        unquote(block)
        @contexts {:"$contexts", %{}}
      end
    end
  end


  defmacro def({name, line, args}, expr) do
    call              = {name, line, rename_underscore(args)}
    call_with_context = {name, line, args ++ [{:@, line, [{:contexts, line, nil}]}]}
    def1 = CtxServer.Kernel.define(:def, call_with_context, expr,  __CALLER__)
    def2 = CtxServer.Kernel.define(:def, call, proxy_expr(name, rename_underscore(args)), __CALLER__)
    quote do
      unquote(def1)
      unquote(def2)
    end
  end

  defp proxy_expr(name, args) do
    ast = quote do
      args = unquote(args) ++ [{:"$contexts", CtxServer.Contexts.current}]
      IO.puts """
      apply(__MODULE__, unquote(name), args)
        __MODULE__ : #{inspect __MODULE__}
        unquote(name) : #{inspect unquote(name)}
        args : #{inspect args}
      """
      apply(__MODULE__, unquote(name), args)
    end
    [do: ast]
  end

  defp rename_underscore(args) do
    for {name, meta, empty} <- args do
      if name == :_ do
        {:underscore, meta, empty}
      else
        {name, meta, empty}
      end
    end
  end


  defmacro set_default_handlers(_env) do
    quote do
      def handle_call(request, from, state, {:"$contexts", _}) do
        handle_call(request, from, state)
      end
      def handle_cast(request, state, {:"$contexts", _}) do
        handle_cast(request, state)
      end
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
        e -> {'EXIT', Exception.message(e)}
      end
    end
  end
end
