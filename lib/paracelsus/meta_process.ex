defmodule Paracelsus.MetaProcess do

  import Kernel, except: [self: 0, send: 2, spawn: 1]

  defp kernel_receive(fun) do
    receive do
      m -> fun.(m)
    end
  end

  # Overriden Primitives

  def spawn(fun) do
    Kernel.spawn(__MODULE__, :meta_single_init, [fun])
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
    case Process.get(:self) do
      nil -> kernel_receive(fun)
      meta ->
        Kernel.send(meta, {:receive, fun})
        kernel_receive(exec())
    end
  end

  def my_receive(fun) do
    __MODULE__.receive(fun)
  end

  # Single Meta Process

  def meta_single_init(fun) do
    exec = Kernel.spawn(__MODULE__, :exec_init, [])
    f = fn nil -> fun.() end
    Kernel.send(exec, {:apply, f, nil, Kernel.self()})
    kernel_receive(meta_single([], f, :dormant, exec))
  end

  def meta_single(queue, fun, state, exec) do
    fn
      {:receive, fun} ->
        IO.puts "{:receive, _}"
        case queue do
          [message|queue] ->
            Kernel.send(exec, {:apply, fun, message, Kernel.self()})
            kernel_receive(meta_single(queue, fun, :active, exec))
          _ ->
            kernel_receive(meta_single(queue, fun, :dormant, exec))
        end
      {:message, message} ->
        IO.puts "{:message, _} # state: #{state}"
        case state do
          :dormant ->
            Kernel.send(exec, {:apply, fun, message, Kernel.self()})
            kernel_receive(meta_single(queue, fun, :active, exec))
          :active ->
            kernel_receive(meta_single(queue ++ [message], fun, :active, exec))
        end
      {:exit} ->
        IO.puts "{:exit}"
      x ->
        raise "meta-single received unexpected message: #{inspect x}"
    end
  end

  # Execution Process

  def exec_init do
    kernel_receive(exec())
  end

  def exec do
    fn 
      {:apply, fun, message, meta} ->
        Process.put(:self, meta)
        fun.(message)
        Kernel.send(meta, {:exit})
      x ->
        raise "meta-single received unexpected message: #{inspect x}"
    end
  end
end
