# Paracelsus

Add reflective behavior to Elixir processes.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add paracelsus to your list of dependencies in `mix.exs`:

        def deps do
          [{:paracelsus, "~> 0.0.1"}]
        end

  2. Ensure paracelsus is started before your application:

        def application do
          [applications: [:paracelsus]]
        end
