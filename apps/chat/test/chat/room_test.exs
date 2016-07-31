defmodule Chat.RoomTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, room} = Chat.Room.start_link("lhahn", self)
    {:ok, room: room}
  end

  test "joins the chat", %{room: room} do
    assert Chat.Room.join(room, "batata", self) == :ok
    assert Chat.Room.join(room, "batata", self) ==
      {:error, :client_exists}
  end

  test "leaves the chat", %{room: room} do
    assert Chat.Room.leave(room, "batata") ==
      {:error, :not_found}
    assert Chat.Room.join(room, "batata", self) == :ok
    assert Chat.Room.leave(room, "batata") == :ok
  end

  test "broadcasts messages", %{room: room} do
    Process.register self, :test

    assert Chat.Room.leave(room, "batata") ==
      {:error, :not_found}

    {:ok, task} = Task.start_link fn ->
      receive do
        msg -> send :test, msg
      end
    end

    assert Chat.Room.join(room, "batata", task) == :ok
    assert Chat.Room.join(room, "joao", self) == :ok
    Chat.Room.send_message(room, "joao", "hj sou ladrao, artigo 157")

    assert_receive "joao: hj sou ladrao, artigo 157", 3000
  end

  test "room process closes itself when all clients leave", %{room: room} do
    Chat.Room.leave(room, "lhahn")
    refute Process.alive?(room)
  end
end
