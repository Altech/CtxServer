defmodule CtxServer.Macro2 do
  @moduledoc """
  To distinct def/2 macro between any contexts and specific contexts,
  CtxServer.Macro and CtxServer.Macro2 both exist.
  """

  import CtxServer.Macro, only: [proxy_expr: 2, rename_underscore: 1]

  defmacro def({name, line, args}, expr) do
    call              = {name, line, rename_underscore(args)}
    call_with_context = {name, line, args ++ [{:_, line, nil}]}
    def1 = CtxServer.Kernel.define(:def, call_with_context, expr,  __CALLER__)
    def2 = CtxServer.Kernel.define(:def, call, proxy_expr(name, rename_underscore(args)), __CALLER__)
    quote do
      unquote(def1)
      unquote(def2)
    end
  end
end
