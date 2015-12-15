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
        Kernel.send(meta, :receive)
        kernel_receive(fun)
    end
  end

  def my_receive(fun) do
    __MODULE__.receive(fun)
  end

  # Single Meta Process

  def meta_single_init(fun) do
    exec = Kernel.spawn(__MODULE__, :exec_init, [])
    Kernel.send(exec, {:init, fun, Kernel.self()})
    kernel_receive(meta_single([], :dormant, exec))
  end

  def meta_single(queue, state, exec) do
    fn
      {:message, message} ->
        IO.puts "{:message, _}"
        if state == :dormant do
          Kernel.send(Kernel.self, :receive)
        end
        kernel_receive(meta_single(queue ++ [message], :active, exec))
      :receive ->
        IO.puts ":receive"
        case queue do
          [message|queue] ->
            Kernel.send(exec, message)
            kernel_receive(meta_single(queue, :active, exec))
          _ ->
            kernel_receive(meta_single(queue, :dormant, exec))
        end
      :exit ->
        IO.puts ":exit"
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
      {:init, fun, meta} ->
        Process.put(:self, meta)
        fun.()
        Kernel.send(meta, :exit)
      x ->
        raise "exec received unexpected message: #{inspect x}"
    end
  end
end
