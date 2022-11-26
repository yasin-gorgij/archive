defmodule Cargo.Repo do
  use Ecto.Repo,
    otp_app: :cargo,
    adapter: Ecto.Adapters.Postgres
end
