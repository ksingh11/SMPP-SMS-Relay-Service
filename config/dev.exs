import Config

config :logger, :console,
    level: :debug

config :sms_server, SmsServer.Repo,
    database: "sms_server",
    username: "postgres",
    password: "postgres",
    hostname: "localhost"

config :sms_server, :cache,
    auth_cache_ttl: 3600 * 1000   # 1 Hour
  
config :sms_server, :amqp,
    amqp_host: "amqp://kbadmin:s78hfycz31qohxes@localhost:5672/khatabook",
    channel: "kb_channel"
  
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
    host: "smsc-sim.smscarrier.com",
    port: 2775,
    username: "test",
    password: "test",
    request_pdus: true,
    transceiver: true,
    source_name: "ZOSTEL",
    source_ton: 1,
    source_npi: 1,
    dest_ton: 1,
    dest_npi: 1,
    registered_delivery: 0,
    smpp_submit_sm_timeout: 500,
    pdus_timeout: 1000,
    pdus_check_interval: 10_000