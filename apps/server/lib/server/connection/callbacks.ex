defmodule Server.Connection.Callbacks do
  @moduledoc """
  This module implements all of the necessary callbacks
  for the `Server.Connection module.`
  """

  defmodule Server.Connection.Callbacks.State do
    @moduledoc """
    This modules implements the state struct utilized inside
    Server.Connection.Callbacks.
    """

    defstruct(
      username: "Anonymous",
      user_pid: nil,
      rooms: %{},
      active_chat: nil
    )
  end
  # Alias the name, so we can refer to it only with `State`.
  alias Server.Connection.Callbacks.State

  def init([]) do
    {:state_functions, :initial_state , %State{}}
  end

  def terminate(_reason, state, _data) do
    :ok
  end

  #======================================#
  # Initial State                        #
  #======================================#

  def initial_state({:call, from}, {:client_name, name}, state) do
    IO.puts "Client name #{name}"

    {pid, _} = from
    reply = [{:reply, from, {:ok, """
    Commands:
      1 - Join chat: %%join <chat-name>
      2 - Create chat: %%create <chat-name>
      3 - Exit: %%exit
    """}}]

    {:next_state, :main_menu, %{state | username: name, user_pid: pid}, reply}
  end

  def initial_state(event_type, event, state) do
    handle_event(event_type, event, :initial_state, state)
  end

  #======================================#
  # Main Menu State                      #
  #======================================#

  def main_menu({:call, from}, {:join_chat, chat_name}, state) do
    case Chat.Registry.get_room(Chat.Registry, chat_name) do
      {:ok, room} ->
        case Chat.Room.join(room, state.username, self) do
          :ok ->
            new_rooms = state.rooms |> Map.put(chat_name, room)
            new_state = %{state | rooms: new_rooms, active_chat: chat_name}
            reply = [{:reply, from, {:ok, "INFO: You have sucessfuly joined #{chat_name}.\n"}}]
            {:next_state, :chat, new_state, reply}

          {:error, :client_exists} ->
            reply = [{:reply, from, {:ok, "WARN: This username is already used.\n"}}]
            {:next_state, :chat, state, reply}
        end
      {:error, :not_found} ->
        reply = [{:reply, from, {:error, "WARN: Chatroom was not found.\n"}}]
        {:next_state, :main_menu, state, reply}
    end
  end

  def main_menu({:call, from}, {:create_chat, chat_name}, state) do
    case Chat.Registry.create_room(Chat.Registry, chat_name, state.username, self) do
      {:ok, room} ->
        new_rooms = state.rooms |> Map.put(chat_name, room)
        new_state = %{state | rooms: new_rooms, active_chat: chat_name}
        reply = [{:reply, from, {:ok, "INFO: You have sucessfuly created #{chat_name}.\n"}}]
        {:next_state, :chat, new_state, reply}

      {:error, :already_exists} ->
        reply = [{:reply, from, {:error, "WARN: Chatroom already exists.\n"}}]
        {:next_state, :main_menu, state, reply}
    end
  end

  def main_menu(event_type, event, state) do
    handle_event(event_type, event, :main_menu, state)
  end

  #======================================#
  # Chat State                           #
  #======================================#

  def chat({:call, from}, {:send_message, msg}, state) when is_binary(msg) do
    %State{username: name, active_chat: chat_name} = state
    case Chat.Registry.get_room(Chat.Registry, chat_name) do
      {:ok, room} ->
        Chat.Room.send_message(room, name, msg)
        reply = [{:reply, from, :ok}]
        {:next_state, :chat, state, reply}

      {:error, :not_found} ->
        reply = [{:reply, from, {:error, "ERROR: FATAL ERROR! RUN!!!111!\n"}}]
        {:next_state, :chat, state, reply}
    end
  end

  def chat({:call, from}, {:switch_chat, chat_name}, state) do
    if Map.has_key?(state.rooms, chat_name) do
      reply = [{:reply, from, {:ok, "INFO: You have sucessfuly switched to #{chat_name}.\n"}}]
      {:next_state, :chat, %{state | active_chat: chat_name}, reply}
    else
      reply = [{:reply, from, {:ok, "INFO: You are not part of chat #{chat_name}.\n"}}]
      {:next_state, :chat, state, reply}
    end
  end

  def chat(:info, {:chat_message, chat, message}, state) do
    send state.user_pid, {:message, message}
    {:next_state, :chat, state}
  end

  def chat(event_type, event, state) do
    handle_event(event_type, event, :chat, state)
  end

  #======================================#
  # General State                        #
  #======================================#

  def handle_event({:call, from}, :list_chats, state_name, state) do
    %State{rooms: rooms} = state
    rooms_list =
      rooms
      |> Map.keys()
      |> Enum.join("\n")
      |> Kernel.<>("\n")

    reply = [{:reply, from, {:ok, rooms_list}}]
    {:next_state, state_name, state, reply}
  end

  def handle_event({:call, _from}, :exit, _state_name, _state) do
    {:stop, :normal}
  end

  # Ignore events that do not match above.
  def handle_event({:call, from}, _, state_name, state) do
    reply = [{:reply, from, {:error, "WARN: Action not allowed.\n"}}]
    {:next_state, state_name, state, reply}
  end
end
