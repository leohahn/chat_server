defmodule Chat.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, registry} = Chat.Registry.start_link(context.test)
    {:ok, registry: registry}
  end

  test "creates rooms", %{registry: registry} do
    alias Chat.Registry

    assert {:ok, _room} =
      Registry.create_room(registry, "banana", "lhahn", self)

    assert Registry.create_room(registry, "banana", "lhahn", self) ==
      {:error, :already_exists}
  end

  test "removes rooms when they close normally", %{registry: registry} do
    alias Chat.Registry

    assert {:ok, room} =
      Registry.create_room(registry, "banana", "lhahn", self)

    assert {:error, :already_exists} =
      Registry.create_room(registry, "banana", "lhahn", self)

    Agent.stop(room, :normal)

    assert {:ok, room} =
      Registry.create_room(registry, "banana", "lhahn", self)
  end
end
