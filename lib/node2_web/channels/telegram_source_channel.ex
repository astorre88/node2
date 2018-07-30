defmodule Node2Web.TelegramSourceChannel do
  require Logger

  use Node2Web, :channel
  use AMQP

  alias Node2.Chats

  @mq_url      "amqp://guest:guest@rabbit"
  @mq_exchange "node1_exchange"
  @ws_topic    "telegram_source:lobby"
  @ws_command  "shout"

  def join(@ws_topic, _payload, socket) do
    {:ok, socket}
  end

  def handle_in(@ws_command, %{"body" => text} = payload, socket) do
    Chats.create_message(payload)
    broadcast socket, @ws_command, payload

    conn = try_connect()
    {:ok, chan} = Channel.open(conn)
    Basic.publish chan, @mq_exchange, "", text
    {:noreply, socket}
  end

  defp try_connect do
    case Connection.open(@mq_url) do
      {:ok, conn} ->
        conn
      {:error, reason} ->
        Logger.log(:error, "failed for #{inspect reason}")
        :timer.sleep 5000
        try_connect()
    end
  end
end
