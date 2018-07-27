defmodule Node2Web.PageControllerTest do
  use Node2Web.ConnCase

  alias Node2.Chats

  setup do
    {:ok, message} = Chats.create_message(%{body: "Some message"})

    {:ok, message: message}
  end

  test "GET /", %{conn: conn, message: message} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Send"
    assert html_response(conn, 200) =~ message.body
  end
end
