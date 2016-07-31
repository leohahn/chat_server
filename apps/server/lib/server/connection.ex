defmodule Server.Connection do
  @moduledoc """
  This modules implements a chat connection.
  It is created whenever a new `socket` connection is
  accepted by `Server.loop_acceptor`. The communication
  with the `:app` application should happen always here.

  This process should be linked with a Task supervised by
  Server.TaskSupervisor.
  """

  def start_link do
    :gen_statem.start_link(Server.Connection.Callbacks, [], [])
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

  def send_message(conn, message) do
    :gen_statem.call(conn, {:send_message, message})
  end

  def exit(conn) do
    :gen_statem.call(conn, :exit)
  end

end
