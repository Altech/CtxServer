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

  context login: true, payment: :normal do
    def handle_cast(request, state) do
      debug_info(request)
      {:noreply, state}
    end

    def handle_call(request, _, state) do
      debug_info(request)
      {:reply, request, state}
    end
  end

  context login: true, payment: :abnormal do
    def handle_cast(request, state) do
      debug_info(request)
      {:noreply, state}
    end

    def handle_call(request, _, state) do
      debug_info(request)
      {:reply, request, state}
    end
  end
end


quote do
  # CtxServer.switch_context :login, true
  {:ok, pid} = CtxServer.start(CtxServer.Test, [])
  CtxServer.Contexts.update login: true, payment: :normal
  CtxServer.cast(pid, :foo)
  CtxServer.call(pid, :foo)
end
