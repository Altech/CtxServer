defmodule CtxServer.Contexts do
  @dict_key :"$ctx_server_contexts"
  
  def update(context, value) do
    updated = Map.put(current, context, value)
    Process.put(@dict_key, updated)
    :ok
  end

  def update(map) do
    updated = Map.merge(current, map)
    Process.put(@dict_key, updated)
    :ok
  end

  def current do
    Process.get(@dict_key) || %{}
  end
end
