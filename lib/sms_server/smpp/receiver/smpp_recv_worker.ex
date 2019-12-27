defmodule SmsServer.SmppRecvWorker do
    @moduledoc """
        Message receiver worker, started by SMPP Worker,
        after successful connection in transeiver mode.

        Will request for PDUs and log them.
    """
    use GenServer
    require Logger

    def env(attribute), do: Application.get_env(:sms_server, :smpp)[attribute]

    def start_link(child_id, smpp_state) do
        Logger.debug("Strating SMPP receiver process.")
        GenServer.start_link(__MODULE__, smpp_state, name: :"#{child_id}")
    end

    def init(smpp_state) do
        Process.monitor(smpp_state.parent)
        send(self(), :receive)
        {:ok, smpp_state}
    end

    # Log individual messages
    defp process_messages(messages) when is_list(messages) do
        messages
        |> Enum.each(&process_messages(&1))
    end

    defp process_messages({:pdu, %{mandatory: %{short_message: short_message}}}) do
        Logger.info("PDUs: #{inspect short_message}")
    end

    # request for messages, process earlier messages.
    def handle_info(:receive, state) do
        Logger.debug("SMPP Receiver set to receive. For: #{inspect state.esme}")
        messages = SMPPEX.ESME.Sync.pdus(state.esme, env(:pdus_timeout))
        process_messages(messages)
        Process.send_after(self(), :receive, env(:pdus_check_interval))
        {:noreply, state}
    end

    # When receiver's Parent process is down
    def handle_info({:DOWN, _ref, :process, _pid, reason}, _) do
        Logger.error("SMPP RECV: Parent process down, stop smpp recv worker. parent: #{inspect reason}")
        {:stop, :normal, nil}
    end

    def handle_info(message, state) do
        Logger.debug("Flush unexpected message: #{inspect message}")
        {:noreply, state}
    end

    def terminate(reason, state) do
        Logger.info("Terminating SMPP Recv worker: #{inspect reason}, state: #{inspect state}")
    end
end