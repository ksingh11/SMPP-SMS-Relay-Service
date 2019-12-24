defmodule SmsServer.QueuePool do
    @moduledoc """
        Process pool supervisor for AMQP Pool Process.
    """
    use Supervisor
    require Logger
    alias SmsServer.Utils

    @poolsize 2
    def start_link(init_arg) do
        Logger.info("SmsServer.QueuePool: starting process pool")
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    def queue_sms(phone_number, message) do
        queue_data(Utils.sms_queue_data(phone_number, message))
    end

    def queue_data(data) do
        :poolboy.transaction(:amqp_pool, 
            fn(worker) -> SmsServer.QueueWorker.queue_data(worker, data) end)
    end

    defp poolboy_config do
        [
            {:name, {:local, :amqp_pool}},
            {:worker_module, SmsServer.QueueWorker},
            {:size, @poolsize}
        ]
    end

    @impl true
    def init(_init_arg) do
        children = [
            :poolboy.child_spec(:amqp_pool, poolboy_config())
        ]
        Supervisor.init(children, strategy: :one_for_one)
    end
end