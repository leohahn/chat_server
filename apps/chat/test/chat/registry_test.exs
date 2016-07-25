defmodule Chat.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, registry} = Chat.Registry.start_link
    {:ok, registry: registry}
  end

  test "creates rooms", %{registry: registry} do

  end
end
