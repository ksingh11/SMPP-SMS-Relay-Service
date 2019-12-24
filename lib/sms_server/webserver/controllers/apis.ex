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
        response =
            case trigger_sms(conn.params) do
                :ok -> %{success: true, message: "Message Queued"}
                {:error, reason} -> %{success: false, message: reason}
        end
        send_resp(conn, 200, Poison.encode!(response))
    end
end