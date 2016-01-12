defmodule CtxServer.Request do
  @moduledoc """
  Request object with meta data.
  """

  defstruct body: nil, contexts: %{}

  def new(body) do
    %__MODULE__{body: body, contexts: global_contexts}
  end

  defp global_contexts do
    if Code.ensure_loaded?(ApplicationContext) do
      for {name, context} <- CtxServer.Contexts.current_values,
      ApplicationContext.scope(name) == :global, into: %{} do
        {name, context}
      end
    else
      CtxServer.Contexts.current_values
    end
  end
end
