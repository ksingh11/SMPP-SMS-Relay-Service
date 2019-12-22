defmodule SmsServer.QueuePool do
    use Supervisor

    @poolsize 2
    def start_link(init_arg) do
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    def queue_msg(msg) do
        :poolboy.transaction(:amqp_pool, fn(worker) -> SmsServer.QueueWorker.queue_msg(worker, msg) end)
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