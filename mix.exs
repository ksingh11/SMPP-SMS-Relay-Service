defmodule SmsServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :sms_server,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SmsServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.1"},
      {:poison, "~> 4.0"},
      {:config_tuples, "~> 0.3.0"},
      {:poolboy, "~> 1.5"},
      {:amqp, "~> 1.4"},
      {:smppex, "~> 2.3"}
    ]
  end
end
