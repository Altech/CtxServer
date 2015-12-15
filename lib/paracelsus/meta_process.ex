defmodule Paracelsus.MetaProcess do

  def spawn(function) do
    exec = Kernel.spawn(__MODULE__, :exec, [])
    Kernel.spawn(meta_single([], function, :dormant, exec))
  end

  def meta_single(queue, function, state, exec) do
    fn ->
      Kernel.send(exec, {:apply, function, nil, Kernel.self()})
    end
  end

  def exec do
    receive do
      {:apply, function, message, from} ->
        if message do
          function.(message)
        else
          function.()
        end
        send(from, :end)
    end
  end
end
