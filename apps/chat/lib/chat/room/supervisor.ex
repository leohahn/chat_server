defmodule Chat.Room.Supervisor do
  use Supervisor

  @name Chat.Room.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  @doc """
  Creates a new room, with `admin` as the first user.
  """
  def start_room(chat_name, admin, admin_pid) do
    Supervisor.start_child(@name, [chat_name, admin, admin_pid])
  end

  def init(:ok) do
    children = [
      worker(Chat.Room, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
