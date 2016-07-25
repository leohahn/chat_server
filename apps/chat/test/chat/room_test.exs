defmodule Chat.RoomTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, room} = Chat.Room.start_link
    {:ok, room: room}
  end

  test "joins the chat", %{room: room} do
    assert Chat.Room.join(room, "batata", self) == :ok
    assert Chat.Room.join(room, "batata", self) ==
      {:error, :client_exists}
  end

  test "leaves the chat", %{room: room} do
    assert Chat.Room.leave(room, "batata") ==
      {:error, :no_client}
  end
end
