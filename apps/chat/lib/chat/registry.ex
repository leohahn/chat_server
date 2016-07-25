defmodule Chat.Registry do
  use GenServer

  # Server api

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @doc """
  Creates a new room with name `room_name`.

  Returns `:ok` with success, otherwise `{:error, :already_exists}`.
  """
  def create_room(server, room_name) do
    GenServer.call(server, {:create_room, room_name})
  end

  @doc """
  Gets the `pid` of a room.

  If successful, returns the `pid`, otherwise `{:error, :not_found}`.
  """
  def get_room(server, room_name) do
    GenServer.call(server, {:get_room, room_name})
  end

  # Server Callbacks
  # TODO: Handle crashes with monitoring.
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:create_room, room_name}, _from, state) do
    {:ok, pid} = Chat.Room.Supervisor.start_room(room_name)
    if Map.has_key?(room_name) do
      {:reply, {:error, :already_exists}, state}
    else
      {:reply, :ok, Map.put(state, room_name, pid)}
    end
  end

  def handle_call({:get_room, room_name}, _from, state) do
    response = Map.get(state, room_name, {:error, :not_found})
    {:reply, response, state}
  end
end
