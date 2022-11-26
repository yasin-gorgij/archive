import Config

config :house_inventory, HouseInventory.Repo,
  database: "./priv/db/house_inventory.db"

config :house_inventory, ecto_repos: [HouseInventory.Repo]

