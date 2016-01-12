defmodule CtxServer.ContextValue do
  defstruct label: nil, time: nil

  def new(label, time \\ :os.timestamp) do
    %__MODULE__{label: label, time: time}
  end
end
