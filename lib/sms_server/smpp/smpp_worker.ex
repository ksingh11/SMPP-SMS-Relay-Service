defmodule SmsServer.SmppWorker do
    use GenServer
    alias SmsServer.Utils
    require Logger

    @host "smsc-sim.smscarrier.com" #"smpp10.solutions4mobiles.com"
    @port 2775 #2780
    @username "test" # "khatab"
    @password "test"
    @request_pdus true
    @transceiver true
    @source_name "ZOSTEL"
    @source_ton 1
    @source_npi 1
    @dest_ton 1
    @dest_npi 1
    @registered_delivery 0
    @reconnect_interval 5_000
    @smpp_submit_sm_timeout 500

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
            {dest_number, message} ->
                try do
                    GenServer.call(pid, {:send_msg, dest_number, message})
                catch
                    :exit, value ->
                        Logger.error("SMPP worker send_msg Timeout: #{inspect value}")
                        {:error, :timeout}
                end
            _ -> {:error, :invalid_data}
        end
    end

    def handle_call({:send_msg, dest_number, message}, _from, state) do
        Logger.debug("SMPP send_msg phone: #{inspect dest_number}, message: #{inspect message}")
        submit_sm = SMPPEX.Pdu.Factory.submit_sm({@source_name, @source_ton, @source_npi}, 
                                                 {dest_number, @dest_ton, @dest_npi}, 
                                                 message, @registered_delivery)
        
        result = 
        case SMPPEX.ESME.Sync.request(state.esme, submit_sm, @smpp_submit_sm_timeout) do
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
        try do
            esme =
            case SMPPEX.ESME.Sync.start_link(@host, @port) do
                {:ok, esme} -> esme
                other -> throw other
            end
            
            bind_pdu = 
            cond do
                @transceiver -> SMPPEX.Pdu.Factory.bind_transceiver(@username, @password)
                true -> SMPPEX.Pdu.Factory.bind_transmitter(@username, @password)
            end

            # Request bind-data PDU.
            bind_resp = 
            case SMPPEX.ESME.Sync.request(esme, bind_pdu) do
                {:ok, bind_resp} -> Logger.debug("New SMPP Connection: #{inspect bind_resp}")
                                    bind_resp
                other -> throw other
            end
            
            # start PDU receiver process
            receiver =
            cond do
                @request_pdus and @transceiver ->
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
                    Logger.debug("SMPP Connected.")
                    {:noreply, %{esme: esme, receiver: receiver}}
            {:error, reason} ->
                Logger.error("Failed to connect, restarting in #{@reconnect_interval} ms. Error: #{inspect reason}")
                :timer.sleep(@reconnect_interval)
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