defmodule SmsServer.QueueWorker do
    use GenServer
    alias AMQP.Connection
    require Logger

    @host "amqp://kbadmin:s78hfycz31qohxes@localhost:5672/khatabook"
    @reconnect_interval 2_000
    @channel "kb_channel"

    def start_link(_) do
        Logger.info("QueueWorker: starting Queue Genserver")
        GenServer.start_link(__MODULE__, nil, [])
    end

    def init(_args) do
        send(self(), :connect)
        {:ok, nil}
    end

    def queue_data(pid, data) do
        try do
            GenServer.call(pid, {:queue_data, data})
        catch
            :exit, value ->
                Logger.error("SMPP worker send_msg Timeout: #{inspect value}")
                {:error, :timeout}
        end
    end

    def handle_call({:queue_data, data}, _from, state) do
        result =
        case AMQP.Basic.publish(state.channel, "", @channel, data) do
            :ok -> {:ok, :published}
            {:error, reason} -> {:error, reason}
        end
        {:reply, result, state}
    end

    def handle_info(:connect, _state) do
      case Connection.open(@host) do
        {:ok, connection} ->
          # Get notifications when the connection goes down
          Process.monitor(connection.pid)
          {:ok, channel} = AMQP.Channel.open(connection)
          AMQP.Queue.declare(channel, @channel)
          Logger.info("AMQP Connection successful.")
          {:noreply, %{channel: channel, connection: connection}}
  
        {:error, _} ->
          Logger.error("Failed to connect, restarting in #{@reconnect_interval} ms.")       
          :timer.sleep(@reconnect_interval)
          {:stop, :amqp_down, nil}
      end
    end

    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
        Logger.info("AMQP Server disconnected")
        {:stop, {:connection_lost, reason}, nil}
    end

    def terminate(_reason, state) do
        if state != nil do
          AMQP.Connection.close(state.connection)
        end
    end
end