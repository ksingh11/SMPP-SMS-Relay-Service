import Config

config :sms_server, Friends.Repo,
  database: "sms_server_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :sms_server, SmsServer.Repo,
  database: "sms_server_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :sms_server, SmsServer.Repo,
  database: "sms_server_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :sms_server, Cart.Repo,
  database: "sms_server_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :sms_server,
    site_url: "localhost:4001"

config :sms_server, :repo,
    db_name: "Kaushal",
    db_host: "localhost"

config :sms_server, :socket,
    timeout: 120_000,
    ping_interval: 60_000,
    auto_ping_server: false

config :sms_server,
    ecto_repos: [SmsServer.Repo]

config :sms_server, SmsServer.Repo,
    database: "sms_server",
    username: "postgres",
    password: "postgres",
    hostname: "localhost"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env()}.exs"