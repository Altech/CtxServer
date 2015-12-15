defmodule Paracelsus.Macros do

  defmacro def(call, expr \\ nil) do
    {name, _, _} = call
    expr = replace_receive(expr)
    IO.puts Macro.to_string(expr)
    quote do
      Kernel.def unquote(name)(), do: unquote(expr[:do])
    end
  end

  def receive_ast(ast) do
    quote do
      # receive(unquote(args))
    end
  end

  def replace_receive(ast) do
    replace_function(ast, :receive, &{:., &1, [{:__aliases__, &1, [:Paracelsus, :Macros]}, :receive]})
  end

  def replace_function(ast, term, map) do
    cond do
      is_tuple(ast) && tuple_size(ast) == 3 ->
        {name, meta, args} = ast
        name = if (name == term), do: map.(meta), else: name
        {name, meta, replace_function(args, term, map)}
      Keyword.keyword?(ast) ->
        for {key, value} <- ast, do: {key, replace_function(value, term, map)}
      is_list(ast) ->
        for ast_partial  <- ast, do: replace_function(ast_partial, term, map)
      true ->
        ast
    end
  end

end
