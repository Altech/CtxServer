defmodule CtxServer.COP do
  alias CtxServer.Contexts

  defmacro __using__(_) do
    quote location: :keep do
      import CtxServer.COP, only: [switch_context: 2, context: 1]
      import CtxServer.Macro, only: [context: 2]
      Module.register_attribute __MODULE__, :defined_proxies, accumulate: true, persist: false
    end
  end

  def switch_context(name, value) do
    Contexts.update([{name, value}])
  end

  def context(name) do
    Contexts.current(name)
  end
end
