defmodule Node2Web.PageController do
  use Node2Web, :controller

  alias Node2.Chats

  def index(conn, _params) do
    messages = Chats.list_messages
    render conn, "index.html", messages: messages
  end
end
