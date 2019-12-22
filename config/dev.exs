import Config

config :sms_server, :repo,
    db_name: "Kaushal",
    db_host: "localhost"


config :sms_server, :socket,
    timeout: 10_000,
    ping_interval: 60_000