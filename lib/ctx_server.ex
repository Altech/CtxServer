defmodule CtxServer do
  import CtxServer.Macro

  defmacro __using__(_) do
    mod = __MODULE__
    quote location: :keep do
      use GenServer

      def handle_info({unquote(mod.cast_message), req}, state) do
        unquote(mod).handle_cast(__MODULE__, req, state)
      end

      def handle_info({unquote(mod.call_message), from, req}, state) do
        unquote(mod).handle_call(__MODULE__, req, from, state)
      end
    end
  end

  def handle_cast(mod, req, state) do
    mod.handle_cast(req, state)
  end

  def handle_call(mod, req, from, state) do
    val = try do
            mod.handle_call(req, from, state)
          rescue
            e -> {'EXIT', Exception.message(e)}
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
  def cast_message, do: @cast_message
  def call_message, do: @call_message

  # From GenServer module
  
  @spec call(server, term, timeout) :: term
  def call(server, request, timeout \\ 5000) do
    try do
      :gen.call(server, @call_message, request, timeout) # Modified
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
    {@cast_message, req} # Modified
  end

  defp do_send(dest, msg) do
    send(dest, msg)
    :ok
  end

end
