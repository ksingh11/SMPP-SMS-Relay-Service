defmodule SmsServer.Webserver.Router do
    use Plug.Router
  
    plug(:match)
    plug(:dispatch)
  
    get "/" do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Poison.encode!(message()))
    end
  
    defp message do
      %{
        response_type: "in_channel",
        text: "Hello from BOT :)"
      }
    end
  end