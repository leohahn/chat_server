defmodule Chat do
  @moduledoc """
  This application implements a chat registry and chatrooms.
  They give the user the ability to create a chat logic on top of the module.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # The Chat is composed by a worker Registry, which stores
    # the current chat rooms and a chat room supervisor.
    children = [
      worker(Chat.Registry, [Chat.Registry]),
      supervisor(Chat.Room.Supervisor, [])
    ]

    opts = [strategy: :rest_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
