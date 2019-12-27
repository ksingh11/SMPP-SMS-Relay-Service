use Mix.Config

port = String.to_integer(System.get_env("HTTP_PORT") || "4000")
#default_secret_key_base = :crypto.strong_rand_bytes(43) |> Base.encode64

config :sms_server, :web,
    site_url: "localhost:4000",
    port: port

config :sms_server, SmsServer.Repo,
  database: System.get_env("DB_DATABASE") || "sms_server",
  username: System.get_env("DB_USERNAME") || "postgres",
  password: System.get_env("DB_PASSWORD") || "postgres",
  hostname: System.get_env("DB_HOSTNAME")  || "localhost"

config :sms_server, :cache,
  auth_cache_ttl: 3600 * 1000   # 1 Hour

config :sms_server, :amqp,
  amqp_host: System.get_env("AMQP_HOST") || "amqp://kbadmin:s78hfycz31qohxes@localhost:5672/khatabook",
  channel: System.get_env("AMQP_CHANNEL") ||  "kb_channel"

config :sms_server, :consumer,
  poolsize: 5,
  prefetch_count: 5,
  reconnect_interval: 3_000

config :sms_server, :producer,
  poolsize: 5,
  reconnect_interval: 3_000

config :sms_server, :smpp,
  poolsize: 5,
  reconnect_interval: 3_000,
  host: System.get_env("SMPP_HOST") || "smsc-sim.smscarrier.com",
  port: String.to_integer(System.get_env("SMPP_PORT") || "2775"),
  username: System.get_env("SMPP_USER") || "test",
  password: System.get_env("SMPP_PASS") || "test",
  request_pdus: true,
  transceiver: true,
  source_ton: 1,
  source_npi: 1,
  dest_ton: 1,
  dest_npi: 1,
  registered_delivery: 0,
  smpp_submit_sm_timeout: 500,
  pdus_timeout: 1000,
  pdus_check_interval: 10_000