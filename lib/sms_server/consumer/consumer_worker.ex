defmodule SmsServer.ConsumerWorker do
    @moduledoc """
        AMQP Consumer Process
    """
    use GenServer
    alias AMQP.Connection
    require Logger

    @host "amqp://kbadmin:s78hfycz31qohxes@localhost:5672/khatabook"
    @reconnect_interval 3_000
    @channel "kb_channel"
    @prefetch_count 5

    def start_link(_args) do
        Logger.debug("Starting consumer worker genserver")
        GenServer.start_link(__MODULE__, nil, [])
    end

    def init(_args) do
        send(self(), :connect)
        {:ok, nil}
    end

    defp consume(channel, tag, _redelivered, data) do
        Logger.debug("Consumer: Sending message to SMPP")
        case SmsServer.SmppPool.send_msg(data) do
            {:ok, _message_id} ->  
                case AMQP.Basic.ack channel, tag do
                    :ok -> :ok
                    other -> Logger.error("AMQP ACK Failed")
                end
            other -> Logger.error("Consumer send message failed: #{inspect other}")
                case AMQP.Basic.nack channel, tag do
                    :ok -> :ok
                    other -> Logger.error("AMQP NACK Failed")
                end
        end
    end

    def handle_info(:connect, _state) do
        case Connection.open(@host) do
          {:ok, connection} ->
            # Get notifications when the connection goes down
            Logger.info("Consumer: AMQP Connection successful.")
            Process.monitor(connection.pid)
            {:ok, channel} = AMQP.Channel.open(connection)
            AMQP.Queue.declare(channel, @channel)
            AMQP.Basic.qos(channel, prefetch_count: @prefetch_count)
            AMQP.Basic.consume(channel, @channel, self())
            {:noreply, %{channel: channel, connection: connection}}
    
          {:error, _} ->
            Logger.error("Failed to connect, restarting in #{@reconnect_interval} ms.")
            :timer.sleep(@reconnect_interval)
            {:stop, :amqp_conn_down, nil}
        end
      end

    # When AMQP Genserver is down
    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
        Logger.error("Consumer: AMQP Server disconnected")
        {:stop, {:connection_lost, reason}, nil}
    end

    # Confirmation sent by the broker after registering this process as a consumer
    def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
        Logger.info("Consumer registered to AMQP.")
        {:noreply, state}
    end

    # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
    def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
        Logger.warn("Consumer Cancelled!: #{inspect self()}")
        {:stop, {:consumer_cancelled, consumer_tag}, state}
    end

    # Confirmation sent by the broker to the consumer process after a Basic.cancel
    def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, state) do
        Logger.warn("Consumered Cancel request successful.")
        {:noreply, state}
    end

    def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, state) do
        # You might want to run payload consumption in separate Tasks in production
        consume(state.channel, tag, redelivered, payload)
        {:noreply, state}
    end

    def handle_info(msg, state) do
        # For unhandled messages
        Logger.debug("Consumer Got Unexpected message: #{inspect msg}")
        {:noreply, state}
    end

    def terminate(reason, state) do
        Logger.debug("Terminating consumer worker: #{inspect reason}")
        if state != nil do
          AMQP.Connection.close(state.connection)
        end
    end
end