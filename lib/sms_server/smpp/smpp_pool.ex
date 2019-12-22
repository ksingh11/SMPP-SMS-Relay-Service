defmodule SmsServer.SmppPool do
    use Supervisor

    @poolsize 1

    def start_link(init_arg) do
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    def send_msg(text) do
        :poolboy.transaction(:smpp_pool, fn(worker) -> SmsServer.SmppWorker.send_msg(worker, text) end)
    end

    defp poolboy_config do
        [
            {:name, {:local, :smpp_pool}},
            {:worker_module, SmsServer.SmppWorker},
            {:size, @poolsize}
        ]
    end

    @impl true
    def init(_init_arg) do
        children = [
            :poolboy.child_spec(:smpp_pool, poolboy_config())
        ]
        Supervisor.init(children, strategy: :one_for_one)
    end
end