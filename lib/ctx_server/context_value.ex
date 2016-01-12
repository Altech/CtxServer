defmodule CtxServer.ContextValue do
  defstruct label: nil, time: nil

  def new(label, time \\ :os.timestampw) do
    %__MODULE__{label: label, time: time}
  end
end
