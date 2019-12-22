defmodule SmsServer.ConsumerPool do
    use Supervisor

    @poolsize 2
    def start_link(init_arg) do
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    defp poolboy_config do
        [
            {:name, {:local, :consumer_pool}},
            {:worker_module, SmsServer.ConsumerWorker},
            {:size, @poolsize}
        ]
    end

    @impl true
    def init(_init_arg) do
        children = [
            :poolboy.child_spec(:consumer_pool, poolboy_config())
        ]
        Supervisor.init(children, strategy: :one_for_one)
    end
end