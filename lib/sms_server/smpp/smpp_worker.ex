defmodule SmsServer.SmppWorker do
    use GenServer
    alias AMQP.Connection

    @host "smsc-sim.smscarrier.com" #"smpp10.solutions4mobiles.com"
    @port 2775 #2780
    @username "test" # "khatab"
    @password "test"

    def start_link(_) do
        GenServer.start_link(__MODULE__, nil, [])
    end

    def init(_args) do
        {:ok, esme} = SMPPEX.ESME.Sync.start_link(@host, @port)
        bind = SMPPEX.Pdu.Factory.bind_transmitter(@username, @password)
        {:ok, _bind_resp} = SMPPEX.ESME.Sync.request(esme, bind)
        {:ok, %{esme: esme, bind: bind}}
    end

    def send_msg(pid, text) do
        GenServer.call(pid, {:text, text})
    end

    def handle_call({:text, text}, _from, state) do
        IO.puts "Sending pdu"
        submit_sm = SMPPEX.Pdu.Factory.submit_sm({"919839203380", 1, 1}, {"919839203380", 1, 1}, text)
        {:ok, submit_sm_resp} = SMPPEX.ESME.Sync.request(state.esme, submit_sm)
        IO.inspect submit_sm_resp   
        message_id = SMPPEX.Pdu.field(submit_sm_resp, :message_id)
        IO.inspect message_id
        :timer.sleep 5000
        {:reply, message_id ,state}
    end

    def terminate(_reason, state) do
        AMQP.Connection.close(state.connection)
    end
end