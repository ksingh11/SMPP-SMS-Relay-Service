defmodule SmsServer.SmppWorker do
    use GenServer
    alias SmsServer.Utils
    require Logger

    def env(attribute), do: Application.get_env(:sms_server, :smpp)[attribute]

    def start_link(_) do
        {:ok, pid} = GenServer.start_link(__MODULE__, nil, [])
        Logger.debug("Started SMPP Worker Client Process: #{inspect pid}")
        {:ok, pid}
    end

    def init(_args) do
        send(self(), :connect_smpp)
        {:ok, nil}
    end

    # call for SMPP send message
    def send_msg(pid, data) do
        case Utils.parse_queue_data(data) do
            {sender, dest_number, message} ->
                try do
                    GenServer.call(pid, {:send_msg, sender, dest_number, message})
                catch
                    :exit, value ->
                        Logger.error("SMPP worker send_msg Timeout: #{inspect value}")
                        {:error, :timeout}
                end
            _ -> {:error, :invalid_data}
        end
    end

    def handle_call({:send_msg, sender, dest_number, message}, _from, state) do
        Logger.debug("SMPP send_msg [#{inspect sender}] phone: #{inspect dest_number}, message: #{inspect message}")
        submit_sm = SMPPEX.Pdu.Factory.submit_sm({sender, env(:source_ton), env(:source_npi)}, 
                                                 {dest_number, env(:dest_ton), env(:dest_npi)}, 
                                                 message, env(:registered_delivery))
        
        result = 
        case SMPPEX.ESME.Sync.request(state.esme, submit_sm, env(:smpp_submit_sm_timeout)) do
            {:ok, submit_sm_resp} -> 
                message_id = SMPPEX.Pdu.field(submit_sm_resp, :message_id)
                {:ok, message_id}
            other -> Logger.error("SMPP Send message error: #{inspect other}")
                {:error, other}
        end
        {:reply, result, state}
    end

    defp smpp_connect() do
        Logger.debug("SMPP Connect method. connecting...")
        Logger.info("SMPP Sever, host: #{inspect env(:host)}, port: #{inspect env(:port)}.")
        try do
            esme =
            case SMPPEX.ESME.Sync.start_link(env(:host), env(:port)) do
                {:ok, esme} -> esme
                other -> throw other
            end
            
            bind_pdu = 
            cond do
                env(:transceiver) -> 
                    Logger.debug("SMPP starting in transceiver mode.")
                    SMPPEX.Pdu.Factory.bind_transceiver(env(:username), env(:password))
                true -> 
                    Logger.debug("SMPP starting in transmitter mode.")
                    SMPPEX.Pdu.Factory.bind_transmitter(env(:username), env(:password))
            end

            # Request bind-data PDU.
            case SMPPEX.ESME.Sync.request(esme, bind_pdu) do
                {:ok, bind_resp} -> 
                    Logger.debug("New SMPP Connection: #{inspect bind_resp}")
                other -> throw other
            end
            
            # start PDU receiver process
            receiver =
            cond do
                env(:request_pdus) and env(:transceiver) ->
                    case SmsServer.SmppReceiverDsup.start_receiver(%{esme: esme, parent: self()}) do
                        {:ok, receiver} -> 
                                Logger.debug("New SMPP Receiver: #{inspect receiver}")
                                receiver
                        other -> throw other
                    end
                true -> nil
            end

            # response
            {:ok, esme, receiver}
        catch
            other -> 
                Logger.error("Error with SMPP Connect method: #{inspect other}")
                {:error, other}
        end
    end

    # Setup SMPP Connection
    def handle_info(:connect_smpp, state) do
        Logger.debug("Setting up SMPP Connection")
        case smpp_connect() do
            {:ok, esme, receiver} -> 
                    Logger.debug("SMPP server Connected.")
                    {:noreply, %{esme: esme, receiver: receiver}}
            {:error, reason} ->
                Logger.error("Failed to connect, restarting in #{inspect env(:reconnect_interval)} ms. Error: #{inspect reason}")
                :timer.sleep(env(:reconnect_interval))
                {:stop, :smpp_conn_fail, state}
        end
    end

    # Handle and unhandle messages to clear the process' mailbox
    def handle_info(message, state) do
        Logger.debug("#{inspect message}")
        {:noreply, state}
    end

    def terminate(reason, state) do
        Logger.debug("Terminating SMPP Worker: #{inspect reason}, terminate recv worker:")
        if state != nil do
            SmsServer.SmppReceiverDsup.terminate_receiver(state.receiver)
        end
    end
end