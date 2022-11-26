# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :cargo,
  ecto_repos: [Cargo.Repo]

# Configures the endpoint
config :cargo, CargoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1NhAu+7ZCg9J5RkDOmIJZikzW2SG7ZXNG8+KQAlKC7Cwi1+ad0pFIWQ4ifo122jd",
  render_errors: [view: CargoWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Cargo.PubSub,
  live_view: [signing_salt: "O4WVYjZk"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# Set Fa as the default language
config :cargo, CargoWeb.Gettext, default_locale: "fa"
