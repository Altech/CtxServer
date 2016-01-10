# CtxServer

Provide Context-Aware Servers in Elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ctx_server to your list of dependencies in `mix.exs`:

        def deps do
          [{:ctx_server, "~> 0.0.1"}]
        end

  2. Ensure ctx_server is started before your application:

        def application do
          [applications: [:ctx_server]]
        end
