defmodule CtxServer.Contexts do
  @dict_key :"$ctx_server_contexts"
  
  def update(map) do
    updated = Enum.into(map, current)
    Process.put(@dict_key, updated)
    :ok
  end

  def current(name) do
    current[name]
  end

  def current do
    Process.get(@dict_key) || %{}
  end
end
