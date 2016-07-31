# Server

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `server` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:chat_server, "~> 0.1.0"}]
    end
    ```

  2. Ensure `chat_server` is started before your application:

    ```elixir
    def application do
      [applications: [:chat_server]]
    end
    ```

