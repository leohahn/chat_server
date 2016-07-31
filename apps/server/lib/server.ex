defmodule Server do
  @moduledoc """
  Implements a tcp server. This server accepts connections
  through tcp and connects the client to the chat application.
  This is designed to work mainly with a `telnet` client.
  """

  use Application
  require Logger
  alias Server.Connection

  @port 4040

  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Server.ClientConnection.Supervisor, []),
      worker(Task, [Server, :accept, [@port]])
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def accept(port) do
    {:ok, listen} = :gen_tcp.listen(
      port,
      [
        :binary,             # The data is binary.
        packet: :line,       # A packet ends with a `\n`.
        active: :once,       # Sets active mode for one message.
        reuseaddr: true      # Allows address reuse.
      ])

    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(listen)
  end

  defp loop_acceptor(listen) do
    alias Server.ClientConnection
    # Accept a new client connection through the socket.
    {:ok, client} = :gen_tcp.accept(listen)
    # Creates a new process that handles the new connection.
    {:ok, client_conn} = ClientConnection.Supervisor.start_child(
      client
    )
    # Sets the new process as the controller of the client connection.
    :ok = :gen_tcp.controlling_process(client, client_conn)
    # Repeats the process to potentially other clients.
    loop_acceptor(listen)
  end

  # This function runs inside a `Task`. It is responsible to communicate
  # the current `socket` (client) with the `Chat` application.
  defp serve(socket, conn) do
    alias Server.Command

    socket
    |> read_line()
    |> Command.parse()
    |> send_to_chat_conn(conn)
    |> write_line(socket)

    serve(socket, conn)
  end

  # This function assumes a parsed command.
  # It sends the command as a event to `Server.Connection`.
  defp send_to_chat_conn({:join, chat_name}, conn) do
    conn
    |> Connection.join_chat(chat_name)
    |> case do
         {_, msg} -> msg
       end
  end

  defp send_to_chat_conn({:create, chat_name}, conn) do
    conn
    |> Connection.create_chat(chat_name)
    |> case do
         {:ok, msg} -> msg
         {:error, reason} -> reason
       end
  end

  defp send_to_chat_conn({:client_name, client_name}, conn) do
    conn
    |> Connection.client_name(client_name)
    |> case do
         {_, msg} -> msg
         {:error, reason} -> reason
       end
  end

  defp send_to_chat_conn({:message, message}, conn) do
    conn
    |> Connection.send_message(message)
    |> case do
         :ok -> ""
         {:error, reason} -> reason
       end
  end

  defp send_to_chat_conn(_unknown, conn) do
    "ERROR: Unknown command.\n"
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(data, socket) do
    :gen_tcp.send(socket, data)
  end
end
