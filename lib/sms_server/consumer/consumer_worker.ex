defmodule SmsServer.ConsumerWorker do
    use GenServer
    alias AMQP.Connection
    require Logger

    @host "amqp://kbadmin:s78hfycz31qohxes@localhost:5672/khatabook"
    @reconnect_interval 3_000
    @channel "kb_channel"

    def start_link(_args) do
        Logger.debug("Starting consumer worker")
        GenServer.start_link(__MODULE__, nil, [])
        # GenServer.start_link(__MODULE__, child_id, name: :"#{child_id}")
    end

    def init(child_id) do
        send(self(), :connect)
        {:ok, nil}
    end

    def handle_info(:connect, _state) do
        case Connection.open(@host) do
          {:ok, connection} ->
            # Get notifications when the connection goes down
            IO.puts "AMQP Connection successful."
            Process.monitor(connection.pid)
            {:ok, channel} = AMQP.Channel.open(connection)
            AMQP.Queue.declare(channel, @channel)
            AMQP.Basic.consume(channel, @channel, self(), no_ack: true)
            {:noreply, %{channel: channel, connection: connection}}
    
          {:error, _} ->
            IO.puts "Failed to connect, restarting in #{@reconnect_interval} ms."           
            :timer.sleep(@reconnect_interval)
            {:stop, :amqp_conn_down, nil}
        end
      end

    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
        IO.puts "AMQP Server disconnected"
        {:stop, {:connection_lost, reason}, nil}
    end

    def handle_info(msg, state) do
        # IO.inspect "Consumer (#{state.name}) got message:"
        IO.inspect msg
        case msg do
            {:basic_deliver, text, _meta} ->
                IO.inspect text
                SmsServer.SmppPool.send_msg(text)
            other -> IO.inspect other
        end

        {:noreply, state}
    end

    def terminate(_reason, state) do
        if state != nil do
          AMQP.Connection.close(state.connection)
        end
    end
end