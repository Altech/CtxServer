defmodule CtxServer.Test do
  use CtxServer

  def handle_call(_, _, state) do
    IO.puts "call!"
    {:reply, Process.get(:"$ctx_server_contexts"), state}
  end

  def handle_cast(_, state) do
    IO.puts "cast!"
    switch_context(:login, true)
    {:noreply, state}
  end
end


quote do
  {:ok, pid} = CtxServer.start(CtxServer.Test, [])
  CtxServer.cast(pid, :foo)
  CtxServer.call(pid, :foo)
end
