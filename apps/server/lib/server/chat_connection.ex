defmodule Server.ChatConnection do
  @moduledoc """
  This modules implements a chat connection.
  It is created pairwise with a `Server.ClientConnection`.

  It provides an API that allows the user to communicate with the
  `Server.ChatConnection` finite state machine. This fsm implements
  the chat logic, communicating with the `:chat` application.
  """

  def start_link do
    :gen_statem.start_link(Server.ChatConnection.Callbacks, [], [])
  end

  def client_name(conn, name) do
    :gen_statem.call(conn, {:client_name, name})
  end

  def join_chat(conn, chat_name) do
    :gen_statem.call(conn, {:join_chat, chat_name})
  end

  def create_chat(conn, chat_name) do
    :gen_statem.call(conn, {:create_chat, chat_name})
  end

  def switch_chat(conn, chat_name) do
    :gen_statem.call(conn, {:switch_chat, chat_name})
  end

  def send_message(conn, message) do
    :gen_statem.call(conn, {:send_message, message})
  end

  def list_chats(conn) do
    :gen_statem.call(conn, :list_chats)
  end

  def help(conn) do
    :gen_statem.call(conn, :help)
  end

  def active_chat(conn) do
    :gen_statem.call(conn, :active_chat)
  end

  def exit(conn) do
    :ok = :gen_statem.stop(conn)
  end

end
