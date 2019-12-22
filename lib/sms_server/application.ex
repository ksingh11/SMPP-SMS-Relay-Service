defmodule SmsServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: SmsServer.Worker.start_link(arg)
      # {SmsServer.Worker, arg}
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: SmsServer.Webserver.Endpoint,
        options: [port: 4000]
      ),
      
      # supervisor(SmsServer.SmppPool, [[]]),
      # supervisor(SmsServer.ConsumerDsup, [[]]),
      supervisor(SmsServer.ConsumerPool, [[]]),
      # supervisor(SmsServer.QueuePool, [[]])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SmsServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
