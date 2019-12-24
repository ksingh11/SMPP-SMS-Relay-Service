defmodule SmsServer.Utils do
    # extract phone number and message from data.
    def parse_queue_data(data) do
        try do
            [dest_number, message] = String.split(data, ":", parts: 2)
            {dest_number, message}
        rescue
            FunctionClauseError -> :error
        end
    end

    # Join phone number, message to be queued
    def sms_queue_data(phone_number, message) do
        "#{phone_number}:#{message}"
    end
end