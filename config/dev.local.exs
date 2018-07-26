use Mix.Config

# Configure your database
config :node2, Node2.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "ee",
  password: "ee",
  database: "node2_dev",
  hostname: "localhost",
  pool_size: 10
