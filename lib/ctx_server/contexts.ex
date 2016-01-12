defmodule CtxServer.Contexts do
  alias CtxServer.ContextValue, as: ContextValue

  @dict_key :"$ctx_server_contexts"
  
  def update(map) do
    time = :os.timestamp
    updated = for {name, label} <- map, into: current do
                {name, ContextValue.new(label, time)}
              end
    Process.put(@dict_key, updated)
    :ok
  end

  def update_values(values) do
    updated = for {name, value} <- values, into: current do
                {name, value} # [TODO] compare time and raise if older and priority:time
              end
    Process.put(@dict_key, updated)
    :ok
  end

  def current(name) do
    current[name]
  end

  def current do
    IO.inspect current_values
    for {name, context} <- current_values, into: %{} do
      {name, context.label}
    end
  end

  def current_values do
    Process.get(@dict_key) || %{}
  end
end
