defmodule SmsServer.Repo do
  use Ecto.Repo,
    otp_app: :sms_server,
    adapter: Ecto.Adapters.Postgres
end
