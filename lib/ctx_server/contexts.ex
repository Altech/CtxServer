defmodule CtxServer.Contexts do
  alias CtxServer.ContextValue, as: ContextValue

  @dict_key :"$ctx_server_contexts"
  
  def update(map) do
    # [TODO] Validate when defined ApplicationContexts
    time = :os.timestamp
    updated = for {name, label} <- map, into: stored_current do
                {name, ContextValue.new(label, time)}
              end
    Process.put(@dict_key, updated)
    :ok
  end

  def update_values(values) do
    updated = for {name, value} <- values, into: current_values do
      validate(name, value, current_values[name])
    end
    Process.put(@dict_key, updated)
    :ok
  end

  defp validate(name, sender_value, receiver_value) do
    if Code.ensure_loaded?(ApplicationContexts) &&
      ApplicationContexts.priority(name) == :newer &&
      sender_value.label != receiver_value.label &&
      !(sender_value.time > receiver_value.time) do
      raise "Inconsistency"
    else
      {name, sender_value}
    end
  end

  def current(name) do
    current[name]
  end

  def current do
    Map.merge(stored_current, computed_current)
  end

  def stored_current do
    for {name, context} <- current_values, into: %{} do
      {name, context.label}
    end
  end

  def computed_current do
    if Code.ensure_loaded?(ApplicationContexts) do
      for name <- ApplicationContexts.computed_contexts, into: %{} do
        {name, ApplicationContexts.context(name)}
      end
    else
      %{}
    end
  end

  def current_values do
    Process.get(@dict_key) || %{}
  end
end
