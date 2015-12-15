defmodule Paracelsus.MetaProcess do

  import Kernel, except: [self: 0, send: 2]

  def spawn(function) do
    exec = Kernel.spawn(__MODULE__, :exec, [])
    meta = Kernel.spawn(meta_single([], function, :dormant, exec))
    Kernel.send(meta, {:init})
    meta
  end

  def meta_single(queue, function, state, exec) do
    fn ->
      receive do
        {:init} ->
          Kernel.send(exec, {:apply, function, nil, Kernel.self()})
          meta_single(queue, function, :active, exec).()
        {:receive, fun} ->
          IO.puts "{:receive, _}"
          case queue do
            [message|queue] ->
              Kernel.send(exec, {:apply, fun, message, Kernel.self()})
              meta_single(queue, fun, :active,  exec).()
            _ ->
              meta_single(queue, fun, :dormant, exec).()
          end
        {:message, message} ->
          IO.puts "{:message, _} # state: #{state}"
          case state do
            :dormant ->
              Kernel.send(exec, {:apply, function, message, Kernel.self()})
              meta_single(queue, function, :active, exec).()
            :active ->
              meta_single(queue ++ [message], function, :active, exec).()
          end
        {:end} ->
          IO.puts "exit!"
        x ->
          raise "meta-single received unexpected message: #{inspect x}"
      end
    end
  end

  def exec do
    receive do # This is special form of `receive`.
      {:apply, function, message, meta} ->
        Process.put(:self, meta)
        if message do
          function.(message)
        else
          function.()
        end
        Kernel.send(meta, {:end})
      x ->
        raise "meta-single received unexpected message: #{inspect x}"
    end
  end

  def self do
    case Process.get(:self) do
      nil -> Kernel.self()
      val -> val
    end
  end

  def send(dest, message) do
    Kernel.send(dest, {:message, message})
  end

  def receive(fun) do
    Kernel.send(Process.get(:self), {:receive, fun})
    exec()
  end
end
