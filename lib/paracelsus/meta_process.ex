defmodule Paracelsus.MetaProcess do

  def spawn(function) do
    exec = Kernel.spawn(__MODULE__, :exec, [])
    meta = Kernel.spawn(meta_single([], function, :dormant, exec))
    send(meta, {:init})
    meta
  end

  def meta_single(queue, function, state, exec) do
    fn ->
      receive do
        {:init} ->
          Kernel.send(exec, {:apply, function, nil, Kernel.self()})
          meta_single(queue, function, :active, exec).()
        {:end} ->
          IO.puts "exit!"
        x ->
          raise "meta-single received unexpected message: #{inspect x}"
      end
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
        Kernel.send(meta, {:end})
    end
  end

  def self do
    case Process.get(:self) do
      nil -> Kernel.self()
      val -> val
    end
  end
end
