defmodule Chat.Room do
  @moduledoc """
  Module that implements a chat room.
  This module works with workers, which are spawned from
  their supervisor and communicated with the public API.
  """

  @doc """
  Starts a new room process, with `admin` as admin.
  """
  def start_link(admin, admin_pid) do
    ret = {:ok, pid} = Agent.start_link(fn -> %{} end)
    join(pid, admin, admin_pid)
    ret
  end

  @doc """
  Joins the `room` with `client_name` and `client_pid`.

  Returns `{:error, :duplicated_name}` if `client_name` already
  exists, otherwise returns `:ok`.
  """
  def join(room, client_name, client_pid) do
    IO.puts "#{client_name} joining"
    chat_state = Agent.get(room, &(&1))
    if client_name in Map.keys(chat_state) do
      {:error, :client_exists}
    else
      Agent.update(room, &Map.put(&1, client_name, client_pid))
    end
  end

  @doc """
  The `client_name` sends a `message` to `room`. The `room` broadcasts
  the message to all connected clients.

  Returns `:ok` if successful, `{:error, :not_found}` if client non existent.
  """
  def send_message(room, client_name, message) when is_binary(message) do
    chat_state = Agent.get(room, &(&1))
    if Map.has_key?(chat_state, client_name) do
      chat_state
      |> Enum.filter(fn {name, _pid} -> name != client_name end)
      |> Keyword.values()
      |> Enum.each(fn pid ->
        send pid, {:chat_message, self, "#{client_name}: " <> message}
      end)
    else
      {:error, :not_found}
    end
  end

  @doc """
  Leaves `room` as `client_name`.

  Returns `{:error, :not_found}` if `client_name` does not exist.
  """
  def leave(room, client_name) do
    # Removes client_name from the Agent.
    res = Agent.get_and_update room, fn state ->
      case Map.pop(state, client_name) do
        {nil, state} ->
          {{:error, :not_found}, state}
        {return, state} ->
          {:ok, state}
      end
    end
    # Checks if the Agent's state is empty, if so kills the process.
    if Enum.empty?(Agent.get(room, &(&1))) do
      Agent.stop(room, :normal)
    end
    res
  end
end
