defmodule Server.ChatConnection.Supervisor do
  use Supervisor

  @name Server.ChatConnection.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_child do
    Supervisor.start_child(__MODULE__, [])
  end

  def init(:ok) do
    children = [
      worker(Server.ChatConnection, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
