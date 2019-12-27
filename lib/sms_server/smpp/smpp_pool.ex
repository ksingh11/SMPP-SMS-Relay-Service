defmodule SmsServer.SmppPool do
    @moduledoc """
        SMPP Process Pool to manage SMPP Client Server.
    """
    use Supervisor
    require Logger

    def env(attribute), do: Application.get_env(:sms_server, :smpp)[attribute]

    def start_link(init_arg) do
        Logger.info("SmppPool: starting process pool supervisor.")
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    def send_msg(data) do
        try do
            :poolboy.transaction(:smpp_pool, fn(worker) -> 
                        Logger.debug("SMPP POOL current process: #{inspect worker}")
                        SmsServer.SmppWorker.send_msg(worker, data) end)
        catch
            :exit, value ->
                Logger.error("SMPP pool Timeout: #{inspect value}")
                {:error, :timeout}
        end
    end

    defp poolboy_config do
        [
            {:name, {:local, :smpp_pool}},
            {:worker_module, SmsServer.SmppWorker},
            {:size, env(:poolsize)},
            {:max_overflow, 0}  # Warning: do not keep overflow workers
        ]
    end

    @impl true
    def init(_init_arg) do
        children = [
            :poolboy.child_spec(:smpp_pool, poolboy_config())
        ]
        Supervisor.init(children, strategy: :one_for_one, max_restarts: 3 * env(:poolsize))
    end
end