defmodule CtxServerTest do
  use ExUnit.Case
  doctest CtxServer

  defmodule Test do
    use CtxServer

    defmacro debug_info(request) do
      quote do
        {name, arity} = __ENV__.function
        IO.puts """
        CALL: #{name}/#{arity}
        request: #{unquote(request)},
        contexts: #{inspect CtxServer.Contexts.current}
        """
      end
    end

    context login: true, payment: :normal do
      def handle_cast(request, state) do
        debug_info(request)
        {:noreply, state}
      end

      def handle_call(request, _, state) do
        debug_info(request)
        {:reply, request, state}
      end
    end

    context login: true, payment: :abnormal do
      def handle_cast(request, state) do
        debug_info(request)
        {:noreply, state}
      end

      def handle_call(request, _, state) do
        debug_info(request)
        {:reply, request, state}
      end
    end

    context :any do
      def handle_cast(request, state) do
        debug_info(request)
        {:noreply, state}
      end

      def handle_call(request, _, state) do
        debug_info(request)
        {:reply, request, state}
      end
    end

    context login: true do
      def foo do
        IO.puts "context(:login) = #{context(:login)}"
        IO.puts "foo(login: true)"
      end
    end

    context login: false do
      def foo do
        IO.puts "foo(login: false)"
      end
    end

    context :any do
      def foo do
        IO.puts "foo(any)"
      end
    end
  end

  test "cast and call" do
    # CtxServer.switch_context :login, true
    {:ok, pid} = CtxServer.start(Test, [])
    CtxServer.Contexts.update login: true, payment: :normal
    CtxServer.cast(pid, :foo)
    CtxServer.call(pid, :foo)
  end

  test "foo" do
    CtxServer.Contexts.update login: true
    Test.foo
  end
end
