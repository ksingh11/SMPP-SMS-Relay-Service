defmodule SmsServer.QueueWorker do
    use GenServer
    alias AMQP.Connection

    @host "amqp://kbadmin:s78hfycz31qohxes@localhost:5672/khatabook"
    @reconnect_interval 2_000
    @channel "kb_channel"

    def start_link(_) do
        IO.puts "Starting Queue"
        GenServer.start_link(__MODULE__, nil, [])
    end

    def init(_args) do
        send(self(), :connect)
        {:ok, nil}
    end

    def queue_msg(pid, message) do
        GenServer.cast(pid, {:msg, message})
    end

    def handle_cast({:msg, msg}, state) do
        AMQP.Basic.publish(state.channel, "", @channel, msg)
        {:noreply, state}
    end

    def handle_info(:connect, _state) do
      case Connection.open(@host) do
        {:ok, connection} ->
          # Get notifications when the connection goes down
          Process.monitor(connection.pid)
          {:ok, channel} = AMQP.Channel.open(connection)
          AMQP.Queue.declare(channel, @channel)
          IO.puts "AMQP Connection successful."
          {:noreply, %{channel: channel, connection: connection}}
  
        {:error, _} ->
          IO.puts "Failed to connect, restarting in #{@reconnect_interval} ms."           
          :timer.sleep(@reconnect_interval)
          {:stop, :amqp_down, nil}
      end
    end

    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
        IO.puts "AMQP Server disconnected"
        {:stop, {:connection_lost, reason}, nil}
    end

    def terminate(_reason, state) do
        if state != nil do
          AMQP.Connection.close(state.connection)
        end
    end
end