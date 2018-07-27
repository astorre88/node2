defmodule Node2Web.TelegramSourceChannelTest do
  use Node2Web.ChannelCase

  alias Node2Web.TelegramSourceChannel
  alias Node2.Chats

  setup do
    {:ok, _, socket} =
      socket("user_id", %{some: :assign})
      |> subscribe_and_join(TelegramSourceChannel, "telegram_source:lobby")

    {:ok, socket: socket}
  end

  test "shout broadcasts to telegram_source:lobby", %{socket: socket} do
    push socket, "shout", %{"body" => "Hello!"}
    assert_broadcast "shout", %{"body" => "Hello!"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"body" => "Hello!"}
    assert_push "broadcast", %{"body" => "Hello!"}
  end
end
