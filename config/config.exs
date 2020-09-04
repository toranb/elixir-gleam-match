# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :game, GameWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GwLnkgaSOj7v/g2aAYLHYfwkOA+Si55i4EzIMdlMJfvDHNm8hyLKpe4FRFvemFC3",
  render_errors: [view: GameWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Game.PubSub,
  live_view: [signing_salt: "oAKTjPAE"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
