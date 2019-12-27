defmodule SmsServer.Utils do
    require Logger

    # extract phone number and message from data.
    def parse_queue_data(data) do
        try do
            [sender, dest_number, message] = String.split(data, ":", parts: 3)
            {sender, dest_number, message}
        rescue
            FunctionClauseError -> :error
        end
    end

    # Join phone number, message to be queued
    def sms_queue_data(sender, phone_number, message) do
        "#{sender}:#{phone_number}:#{message}"
    end

    # queue sms to amqp pool
    def queue_sms(sender, phone_number, message) do
        SmsServer.QueuePool.queue_data(sms_queue_data(sender, phone_number, message))
    end
end