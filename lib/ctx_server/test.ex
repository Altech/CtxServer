defmodule CtxServer.Test do
  use CtxServer

  def handle_call(_, _, state) do
    IO.puts "call!"
    {:reply, :ok, state}
  end

  def handle_cast(_, state) do
    IO.puts "cast!"
    {:noreply, state}
  end
end


quote do
  {:ok, pid} = CtxServer.start(CtxServer.Test, [])
  CtxServer.cast(pid, :foo)
  CtxServer.call(pid, :foo)
end
