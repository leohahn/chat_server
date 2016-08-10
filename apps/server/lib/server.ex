defmodule Server do
  @moduledoc """
  Implements a Server module, which makes tcp connections with clients
  and communicates with the `:chat` application.
  """

  use Application
  require Logger

  @port 4040

  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Server.ClientConnection.Supervisor, []),
      supervisor(Server.ChatConnection.Supervisor, []),
      worker(Task, [Server, :accept, [@port]])
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Listens and accepts TCP connections on a given `port`.
  New connections spawn a new `Server.ClientConnection` server.
  """
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
end
