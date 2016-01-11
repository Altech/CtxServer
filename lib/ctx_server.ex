defmodule CtxServer do
  import CtxServer.Macro

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
    end
  end

  defdelegate_module GenServer
end
