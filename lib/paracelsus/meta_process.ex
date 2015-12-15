defmodule Paracelsus.MetaProcess do

  def spawn(function) do
    exec = Kernel.spawn(__MODULE__, :exec, [])
    Kernel.send(exec, {:apply, function})
    # Kernel.spawn(meta1([], function, :dormant, exec))
  end

  defp meta1(queue, function, state, exec) do
    Kernel.send(exec, {:apply, Kernel.self()})
  end

  require Paracelsus.Macros

  import Kernel, except: [def: 2]
  import Paracelsus.Macros, only: [def: 2]

  def exec do
    receive do
      fn
        message -> exec_internal(message)
      end
    end
  end

  ast = quote do
    def exec do
      receive do
        message -> exec_internal(message)
      end
    end
  end

  IO.puts Macro.to_string(Macro.expand(ast, __ENV__))

  
  defp exec_internal({:apply, function}) do
    function.()
  end

  defp exec_internal({:apply, function, message}) do
    function.(message)
  end
end
