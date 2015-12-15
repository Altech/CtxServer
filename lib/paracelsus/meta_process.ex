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
      {:apply, function, message, meta} ->
        Process.put(:self, meta)
        if message do
          function.(message)
        else
          function.()
        end
        send(meta, :end)
    end
  end

  def self do
    case Process.get(:self) do
      nil -> Kernel.self()
      val -> val
    end
  end
end
