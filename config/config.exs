import Config

config :sms_server,
    site_url: "localhost:4001"

config :sms_server, :repo,
    db_name: "Kaushal",
    db_host: "localhost"

config :sms_server, :socket,
    timeout: 120_000,
    ping_interval: 60_000,
    auto_ping_server: false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env()}.exs"