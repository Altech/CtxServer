defmodule Paracelsus.MetaProcess do

  def spawn do
    Kernel.spawn(&meta1/0)
  end

  defp meta1 do
    IO.puts "foo"
  end

end
