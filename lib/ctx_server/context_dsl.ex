defmodule CtxServer.ContextDSL do
  defmacro __using__(_) do
    quote do
      import CtxServer.ContextDSL, only: [defcontext: 2]
      Module.register_attribute __MODULE__, :context_definitions, accumulate: true, persist: false
      @before_compile CtxServer.ContextDSL
    end
  end

  defmacro defcontext(name, do: computation) do
    quote do
      @context_definitions unquote({name, Macro.escape(computation)})
    end
  end

  defmacro defcontext(name, opts \\ []) do
    scope = opts[:scope] || :global
    priority = opts[:priority] || :sender
    quote do
      @context_definitions unquote(Macro.escape({name, scope, priority}))
    end
  end

  defmacro __before_compile__(env) do
    definitions = Module.get_attribute(env.module, :context_definitions)
    ast1 = for definition <- definitions do
             context_ast(definition)
           end
    ast2 = computed_contexts_ast(definitions)
    [ast2|ast1]
  end

  defp context_ast({name, scope, priority}) do
    quote do
      def context(unquote(name)) do
        CtxServer.Contexts.stored_current[unquote(name)]
      end
      def scope(unquote(name)), do: unquote(scope)
      def priority(unquote(name)), do: unquote(priority)
    end
  end

  defp context_ast({name, computation}) do
    quote do
      def context(unquote(name)) do
        unquote(computation)
      end
    end
  end

  defp computed_contexts_ast(definitions) do
    computed_contexts = for {name, _} <- definitions, do: name
    quote do
      def computed_contexts do
        unquote(computed_contexts)
      end
    end
  end
end
