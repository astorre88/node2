defmodule Node2Web.PageController do
  use Node2Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
