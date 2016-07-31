defmodule Chat.Registry do
  use GenServer

  #=====================#
  # Server api          #
  #=====================#

  @doc """
  Starts a new registry process, with name `name`.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @doc """
  Creates a new room with name `room_name`.

  Returns `:ok` with success, otherwise `{:error, :already_exists}`.
  """
  def create_room(server, room_name, admin, admin_pid) do
    GenServer.call(server, {:create_room, room_name, admin, admin_pid})
  end

  @doc """
  Gets the `pid` of a room.

  If successful, returns `pid`, otherwise `{:error, :not_found}`.
  """
  def get_room(server, room_name) do
    GenServer.call(server, {:get_room, room_name})
  end

  ##################
  # Server Callbacks
  ##################

  def init(:ok) do
    rooms = %{}
    refs = %{}
    {:ok, {rooms, refs}}
  end

  def handle_call({:create_room, room_name, admin, admin_pid}, _from, state) do
    {rooms, refs} = state
    if Map.has_key?(rooms, room_name) do
      {:reply, {:error, :already_exists}, state}
    else
      {:ok, pid} = Chat.Room.Supervisor.start_room(admin, admin_pid)
      ref = Process.monitor(pid)
      new_rooms = Map.put(rooms, room_name, pid)
      new_refs = Map.put(refs, ref, room_name)
      {:reply, {:ok, pid}, {new_rooms, new_refs}}
    end
  end

  def handle_call({:get_room, room_name}, _from, state) do
    {rooms, _refs} = state
    response = Map.get(rooms, room_name)
    if response do
      {:reply, {:ok, response}, state}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, :normal}, {rooms, refs}) do
    {room_name, new_refs} = Map.pop(refs, ref)
    new_rooms = Map.delete(rooms, room_name)

    IO.puts "Room #{room_name} closing."

    {:noreply, {new_rooms, new_refs}}
  end
end
