defmodule SmsServer.QueuePool do
    @moduledoc """
        Process pool supervisor for AMQP Pool Process.
    """
    use Supervisor
    require Logger
    import Application, only: [get_env: 2]
    
    def start_link(init_arg) do
        Logger.info("SmsServer.QueuePool: starting process pool")
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    def queue_data(data) do
        Logger.debug("QueuePool:queuing data: #{data}")
        try do
            :poolboy.transaction(:amqp_pool,
                fn(worker) -> SmsServer.QueueWorker.queue_data(worker, data) end)
        catch
            :exit, value ->
                Logger.error("Queue pool Timeout: #{inspect value}")
                {:error, :timeout}
        end
    end

    defp poolboy_config do
        [
            {:name, {:local, :amqp_pool}},
            {:worker_module, SmsServer.QueueWorker},
            {:size, Application.get_env(:sms_server, :producer)[:poolsize]}
        ]
    end

    @impl true
    def init(_init_arg) do
        children = [
            :poolboy.child_spec(:amqp_pool, poolboy_config())
        ]
        Supervisor.init(children, strategy: :one_for_one, max_restarts: 3 * get_env(:sms_server, :producer)[:poolsize])
    end
end