defmodule Node2.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :body, :text

      timestamps()
    end

  end
end
