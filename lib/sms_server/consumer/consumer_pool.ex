defmodule SmsServer.ConsumerPool do
    @moduledoc """
        Process pool supervisor for AMQP Consumer.
    """
    use Supervisor
    require Logger

    def env(attribute), do: Application.get_env(:sms_server, :consumer)[attribute]

    def start_link(init_arg) do
        Logger.info("ConsumerPool: starting supervisor process.")
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    defp poolboy_config do
        [
            {:name, {:local, :consumer_pool}},
            {:worker_module, SmsServer.ConsumerWorker},
            {:size, env(:poolsize)},
            {:max_overflow, 0}  # Warning: do not keep overflow workers
        ]
    end

    @impl true
    def init(_init_arg) do
        children = [
            :poolboy.child_spec(:consumer_pool, poolboy_config())
        ]
        Supervisor.init(children, strategy: :one_for_one, max_restarts: 3 * env(:poolsize))
    end
end