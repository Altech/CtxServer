defmodule ApplicationContext do
  use CtxServer.Context

  # Define a stored contexts
  defcontext :login,        scope: :global, priority: :sender
  defcontext :payment,      scope: :global, priority: :newer
  defcontext :ip,           scope: :global, priority: :sender
  defcontext :content_type, scope: :local

  # Define a computed context
  defcontext :country do
    IO.puts "called!"
    case context(:ip) do
      {10, _, _} -> :ja
      {20, _, _} -> :en
    end
  end
end
