defmodule CtxServer.Request do
  @moduledoc """
  Request object with meta data.
  """

  defstruct body: nil, contexts: %{}

  def new(body) do
    %__MODULE__{body: body, contexts: global_contexts}
  end

  defp global_contexts do
    # [TODO] Move to Contexts module.
    if Code.ensure_loaded?(ApplicationContexts) do
      for {name, context} <- CtxServer.Contexts.current_values,
      ApplicationContexts.scope(name) == :global, into: %{} do
        {name, context}
      end
    else
      CtxServer.Contexts.current_values
    end
  end
end
