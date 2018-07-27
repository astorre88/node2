defmodule Node2Web.TelegramSourceChannel do
  use Node2Web, :channel

  alias Node2.Chats

  def join("telegram_source:lobby", _payload, socket) do
    {:ok, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (telegram_source:lobby).
  def handle_in("shout", payload, socket) do
    Chats.create_message(payload)
    broadcast socket, "shout", payload
    {:noreply, socket}
  end
end
