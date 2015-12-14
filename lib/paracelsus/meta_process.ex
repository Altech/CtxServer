defmodule Paracelsus.MetaProcess do

  def spawn(f) do
    exec = Kernel.spawn(&exec/0)
    Kernel.spawn(meta1([], f, :dormant, exec))
  end

  defp meta1(queue, function, state, exec) do
    fn ->
      IO.puts "foo"
    end
  end

  defp exec do
  end

end
