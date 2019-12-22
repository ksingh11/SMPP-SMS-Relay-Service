defmodule SmsServer.ConsumerDsup do
    @moduledoc """
        Supervise queue consumer.
    """
    use DynamicSupervisor
    require Logger

    def start_link(args) do
        Logger.debug("Starting Queue consumer DynamicSupervisor.")
        DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
    end

    @impl true
    def init(_args) do
        DynamicSupervisor.init(strategy: :one_for_one, max_seconds: 1)
    end

    def start_child() do
        Logger.debug("Adding Consumer Worker")
        res = DynamicSupervisor.count_children(SmsServer.ConsumerDsup)
        child_id =  "consumer:#{res.workers + 1}"
        Logger.debug("Starting supervised queue consumer worker: #{child_id}")
        spec = %{id: child_id, 
                start: {SmsServer.ConsumerWorker, :start_link, [child_id]},
                restart: :permanent}
        DynamicSupervisor.start_child(__MODULE__, spec)
    end

    def boot_workers(num_workers) do
        Enum.each 1..num_workers, fn (_) -> start_child() end
    end

    def terminate_child(child_pid) do
        Logger.debug("Terminating user server for user_pid: #{inspect child_pid}.")
        DynamicSupervisor.terminate_child(__MODULE__, child_pid)
    end
    
end