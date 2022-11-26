defmodule HouseInventory.Repo do
  use Ecto.Repo,
    otp_app: :house_inventory,
    adapter: Ecto.Adapters.SQLite3
end
