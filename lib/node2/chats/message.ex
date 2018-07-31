defmodule Node2.Chats.Message do
  @moduledoc """
  Message record schema.
  """

  use Ecto.Schema
  import Ecto.Changeset


  schema "messages" do
    field :body, :string

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end
end
