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
      supervisor(Server.Connection.Supervisor, []),
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

  defp write_line(data, socket) do
    :gen_tcp.send(socket, data)
  end
end
