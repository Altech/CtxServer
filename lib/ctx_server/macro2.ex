defmodule CtxServer.Macro2 do
  @moduledoc """
  To distinct def/2 macro between any contexts and specific contexts,
  CtxServer.Macro and CtxServer.Macro2 both exist.
  """

  import CtxServer.Macro, only: [proxy_expr: 2, proxy_args: 1]

  defmacro def({name, line, args}, expr) do
    call              = {name, line, proxy_args(args)}
    call_with_context = {name, line, List.wrap(args) ++ [{:_, line, nil}]}
    def1 = CtxServer.Kernel.define(:def, call_with_context, expr,  __CALLER__)
    def2 = CtxServer.Kernel.define(:def, call, proxy_expr(name, proxy_args(args)), __CALLER__)
    sign = {name, length(List.wrap(args))}
    quote do
      unquote(def1)
      unless Enum.member?(@defined_proxies, unquote(sign)) do
        unquote(def2)
        @defined_proxies unquote(sign)
      end
    end
  end
end
