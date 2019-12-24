defmodule SmsServer.Webserver.Router do
    use Plug.Router
    alias Api.Authentication

    plug(:match)
    plug Authentication
    plug :put_resp_content_type, "application/json"
    plug(:dispatch)
    
    get "/send-message/" do
      conn
      |> WebServer.Apis.send_message
    end
  end