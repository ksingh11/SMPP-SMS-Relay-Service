defmodule WebServer.Apis do
    import Plug.Conn
    require Logger
    
    defp trigger_sms(%{"phone" => phone, "msg" => message}) when is_binary(phone) and is_binary(message) do
        # Trigger SMS
        Logger.debug("Got to send: #{phone}, #{message}")
        SmsServer.QueuePool.queue_sms(phone, message)
    end

    defp trigger_sms(_) do
        Logger.debug("Invalid sms request data.")
        {:error, "Invalid Request"}
    end

    def send_message(conn) do
        case trigger_sms(conn.params) do
            {:ok, _} ->
                send_resp(conn, 200, Poison.encode!(%{success: true, message: "Message Queued"}))
            {:error, reason} ->
                send_resp(conn, 503, Poison.encode!(%{success: false, message: reason}))
        end
    end
end