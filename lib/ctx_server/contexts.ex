defmodule CtxServer.Contexts do
  @dict_key :"$ctx_server_contexts"
  
  def update(context, value) do
    updated = Map.put(current, context, value)
    Process.put(@dict_key, updated)
  end

  defp current do
    Process.get(@dict_key) || %{}
  end
end
