defmodule CtxServer.Request do
  @moduledoc """
  Request object with meta data.
  """

  defstruct body: nil, contexts: %{}

  def new(body) do
    %__MODULE__{body: body, contexts: CtxServer.Contexts.current}
  end
end
