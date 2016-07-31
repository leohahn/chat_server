defmodule Server.Command do
  def parse(command) when is_binary(command) do
    do_parse String.split(command, " ")
  end

  defp do_parse(["%%join", chat_name]) do
    {:join, String.strip(chat_name)}
  end

  defp do_parse(["%%create", chat_name]) do
    {:create, String.strip(chat_name)}
  end

  defp do_parse(["%%username", username]) do
    {:client_name, String.strip(username)}
  end

  defp do_parse(message) do
    IO.puts "parsing message"
    {:message, Enum.join(message, " ")}
  end
end