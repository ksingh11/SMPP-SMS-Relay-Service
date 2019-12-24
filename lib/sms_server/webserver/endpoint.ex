defmodule SmsServer.Webserver.Endpoint do
    use Plug.Router
    require Logger

    plug(Plug.Logger)
    plug(:match)
    plug(Plug.Parsers,
        parsers: [:json],
        pass: ["application/json"],
        json_decoder: Poison
    )
    plug(:dispatch)
    
    forward("/api/v1", to: SmsServer.Webserver.Router)

    match _ do
        send_resp(conn, 404, "Requested page not found!")
    end
end