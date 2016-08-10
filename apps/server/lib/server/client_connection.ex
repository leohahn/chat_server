defmodule Server.ClientConnection do
  @moduledoc """
  This server implements a tcp connection that communicates with
  `Server.ChatConnection`.
  It receives tcp messages asynchronously, parses them in different
  commands and sends them to the chat connection.
  """
  use GenServer
  alias Server.ChatConnection

  #====================#
  # API                #
  #====================#

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  #====================#
  # Callbacks          #
  #====================#

  def init(client) do
    {:ok, conn} = Server.ChatConnection.Supervisor.start_child
    Process.monitor(conn)

    write_line """
    Sucessfuly connected, please enter your name (@username <name>):
    """, client

    schedule_set_active_mode

    {:ok, {client, conn}}
  end

  def handle_info({:tcp, _from, msg}, {client, conn} = state) do
    alias Server.Command

    reply_message =
      msg
      |> Command.parse()
      |> send_to_chat_conn(conn)

    write_line(reply_message, client)

    {:noreply, state}
  end

  def handle_info({:message, msg}, {client, _conn} = state) do
    write_line(msg, client)
    {:noreply, state}
  end

  def handle_info(:set_active_mode, {client, _conn} = state) do
    :inet.setopts(client, [active: :once])
    schedule_set_active_mode()
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, {client, _conn} = state) do
    write_line("Good Bye!\n", client)
    {:stop, :shutdown, state}
  end

  #====================#
  # Internal Functions #
  #====================#

  # This function dispatches based on the command type.
  # It should always return a string based on the result
  # of the function.
  defp send_to_chat_conn({:join, chat_name}, conn) do
    conn
    |> ChatConnection.join_chat(chat_name)
    |> case do
         {_, msg} -> msg
       end
  end

  defp send_to_chat_conn(:help, conn) do
    conn
    |> ChatConnection.help()
    |> case do
         {_, msg} -> msg
       end
  end

  defp send_to_chat_conn(:exit, conn) do
    conn |> ChatConnection.exit()
  end

  defp send_to_chat_conn(:active, conn) do
    conn
    |> ChatConnection.active_chat()
    |> case do
         {_, msg} -> msg
       end
  end

  defp send_to_chat_conn({:create, chat_name}, conn) do
    conn
    |> ChatConnection.create_chat(chat_name)
    |> case do
         {:ok, msg} -> msg
         {:error, reason} -> reason
       end
  end

  defp send_to_chat_conn({:switch, chat_name}, conn) do
    conn
    |> ChatConnection.switch_chat(chat_name)
    |> case do
         {:ok, msg} -> msg
         {:error, reason} -> reason
       end
  end

  defp send_to_chat_conn(:list, conn) do
    conn
    |> ChatConnection.list_chats()
    |> case do
         {:ok, msg} -> msg
         {:error, reason} -> reason
       end
  end

  defp send_to_chat_conn({:client_name, client_name}, conn) do
    conn
    |> ChatConnection.client_name(client_name)
    |> case do
         {:ok, msg} -> msg
         {:error, reason} -> reason
       end
  end

  defp send_to_chat_conn({:message, message}, conn) do
    conn
    |> ChatConnection.send_message(message)
    |> case do
         :ok -> ""
         {:error, reason} -> reason
       end
  end

  defp send_to_chat_conn(_unknown, _conn) do
    "ERROR: Unknown command.\n"
  end

  defp schedule_set_active_mode do
    Process.send_after(self, :set_active_mode, 800)
  end

  defp write_line(data, client) do
    :gen_tcp.send(client, data)
  end
end
