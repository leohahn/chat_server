defmodule Chat.Room.Supervisor do
  use Supervisor

  @name Chat.Room.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_room(room_name) do
    Supervisor.start_child(
      @name, [room_name, [restart: :transient]]
    )
  end

  def init(:ok) do
    children = [
      worker(Chat.Room, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
