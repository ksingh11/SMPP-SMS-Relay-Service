defmodule SmsServer.SmppReceiverDsup do
    @moduledoc """
        Supervise SMPP receiver.
    """
    use DynamicSupervisor
    require Logger

    def start_link(args) do
        Logger.debug("Starting SMPP Receiver' DynamicSupervisor.")
        DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
    end

    @impl true
    def init(_args) do
        DynamicSupervisor.init(strategy: :one_for_one, max_seconds: 1)
    end

    def start_receiver(smpp_state) do
        child_id =  "smpp_recv:#{DynamicSupervisor.count_children(__MODULE__).workers+1}:#{:os.system_time(:nano_seconds)}"
        Logger.debug("Starting SMPP Receiver child worker: #{child_id}, :transient restart")
        spec = %{id: child_id, 
                start: {SmsServer.SmppRecvWorker, :start_link, [child_id, smpp_state]},
                restart: :transient}
        DynamicSupervisor.start_child(__MODULE__, spec)
    end

    def terminate_receiver(receiver_pid) do
        Logger.debug("Terminate instruction smpp recv worker: #{inspect receiver_pid}.")
        DynamicSupervisor.terminate_child(__MODULE__, receiver_pid)
    end
    
end