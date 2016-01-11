defmodule CtxServer do
  import CtxServer.Macro

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
      unquote(handle_info_ast)
    end
  end

  defdelegate_module GenServer, except: [call: 2, call: 3, cast: 2, cast: 3]
  # [TODO] Impl multi_call, abcast version

  @call_message :"$ctx_call"
  @cast_message :"$ctx_cast"

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

  defp handle_info_ast do
    cast_message = @cast_message
    call_message = @call_message
    quote do
      def handle_info({unquote(cast_message), req}, state) do
        IO.puts """
        HANDLE INFO MESSAGE(CAST):
        #{inspect req}
        """
        handle_cast(req, state)
      end

      # https://github.com/blackberry/Erlang-OTP/blob/master/lib/stdlib/src/gen_server.erl#L577-L595
      # https://github.com/blackberry/Erlang-OTP/blob/master/lib/stdlib/src/gen_server.erl#L628-L640
      def handle_info({unquote(call_message), from, req}, state) do
        IO.puts """
        HANDLE INFO MESSAGE(CALL):
        #{inspect req}
        """

        val = try do
                handle_call(req, from, state)
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
    end
  end

end
