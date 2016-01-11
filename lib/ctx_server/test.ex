defmodule CtxServer.Test do
  use CtxServer

  defmacro debug_info(request) do
    quote do
      {name, arity} = __ENV__.function
      IO.puts """
      CALL: #{name}/#{arity}
        request: #{unquote(request)},
        contexts: #{inspect CtxServer.Contexts.current}
      """
    end
  end

  def handle_call(request, _, state) do
    debug_info(request)
    {:reply, request, state}
  end

  def handle_cast(request, state) do
    debug_info(request)
    switch_context(:login, true)
    {:noreply, state}
  end
end


quote do
  {:ok, pid} = CtxServer.start(CtxServer.Test, [])
  CtxServer.cast(pid, :foo)
  CtxServer.call(pid, :foo)
end
