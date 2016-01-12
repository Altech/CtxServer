defmodule CtxServer do
  import CtxServer.Macro
  alias CtxServer.Contexts, as: Contexts
  alias CtxServer.Request, as: Request

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      def handle_info({unquote(CtxServer.cast_message), req}, state) do
        CtxServer.handle_info_cast(__MODULE__, req, state)
      end

      def handle_info({unquote(CtxServer.call_message), from, req}, state) do
        CtxServer.handle_info_call(__MODULE__, req, from, state)
      end

      import CtxServer, only: [switch_context: 2]
      import CtxServer.Macro, only: [context: 2]
    end
  end

  def switch_context(context, value) do
    Contexts.update([{context, value}])
  end

  def handle_info_cast(mod, req, state) do
    Contexts.update_values(req.contexts)

    rescue_with_tuple do
      mod.handle_cast(req.body, state, Contexts.current)
    end
  end

  def handle_info_call(mod, req, from, state) do
    Contexts.update_values(req.contexts)

    val = rescue_with_tuple do
      mod.handle_call(req.body, from, state, Contexts.current)
    end

    case val do
      {:reply, reply, new_state} ->
        :gen_server.reply(from, reply)
        {:noreply, new_state}
      {:reply, reply, new_state, time} ->
        :gen_server.reply(from, reply)
        {:noreply, new_state, time}
      {:stop, reason, reply, new_state} ->
        :gen_server.reply(from, reply) # [TODO] Exactly accurate semantics for this pattern
        {:stop, reason, new_state}
      other -> other
    end
  end

  defdelegate_module GenServer, except: [call: 2, call: 3, cast: 2, cast: 3]
  # [TODO] Impl multi_call, abcast version

  @call_message :"$ctx_call"
  @cast_message :"$ctx_cast"

  # From GenServer module
  
  @spec call(server, term, timeout) :: term
  def call(server, request, timeout \\ 5000) do
    try do
      :gen.call(server, @call_message, Request.new(request), timeout) # Modified
    catch
      :exit, reason ->
        exit({reason, {__MODULE__, :call, [server, request, timeout]}})
    else
      {:ok, res} -> res
    end
  end

  @typedoc "The server reference"
  @type server :: pid | name | {atom, node}

  @typedoc "The GenServer name"
  @type name :: atom | {:global, term} | {:via, module, term}

  @spec cast(server, term) :: :ok
  def cast(server, request)

  def cast({:global, name}, request) do
    try do
      :global.send(name, cast_msg(request))
      :ok
    catch
      _, _ -> :ok
    end
  end

  def cast({:via, mod, name}, request) do
    try do
      mod.send(name, cast_msg(request))
      :ok
    catch
      _, _ -> :ok
    end
  end

  def cast({name, node}, request) when is_atom(name) and is_atom(node),
    do: do_send({name, node}, cast_msg(request))

  def cast(dest, request) when is_atom(dest) or is_pid(dest),
    do: do_send(dest, cast_msg(request))
  
  defp cast_msg(req) do
    {@cast_message, CtxServer.Request.new(req)} # Modified
  end

  defp do_send(dest, msg) do
    send(dest, msg)
    :ok
  end

  # Used in __using__ macro
  def cast_message, do: @cast_message
  def call_message, do: @call_message
end
