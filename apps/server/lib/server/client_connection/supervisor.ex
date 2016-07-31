defmodule Server.ClientConnection.Supervisor do
  @moduledoc """
  Implements a supervisor for the `Server.ClientConnection` module.
  The child worker is created each time a new connection is accepted
  through `:gen_tcp.accept`.
  """

  use Supervisor

  @name Server.ClientConnection.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_child(socket) do
    Supervisor.start_child(__MODULE__, [socket])
  end

  def init(:ok) do
    children = [
      worker(Server.ClientConnection, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
