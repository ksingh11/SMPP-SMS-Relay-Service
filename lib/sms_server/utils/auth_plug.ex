defmodule Api.Authentication do
    @moduledoc """
        Plug module to check for authentication
        Using headers: client_id, client_key
        Also, assign sender to conn.
    """
    import Plug.Conn
    require Logger
    alias SmsServer.CacheHelper

    def init(opts), do: opts

    defp authenticated?(conn) do
        client_id = List.first(get_req_header(conn, "client_id"))
        client_key = List.first(get_req_header(conn, "client_key"))
        authenticated?(client_id, client_key)
    end

    defp authenticated?(client_id, client_key) when is_binary(client_id) and is_binary(client_key) do
        case CacheHelper.get_client_data(client_id) do
            nil -> false
            apikey ->
                {client_key == apikey.key, apikey}
        end
    end

    defp authenticated?(_, _) do false end

    def call(conn, _opts) do
        {is_authenticated, conn} =
        case authenticated?(conn) do
            {true, apikey} ->
                conn = assign(conn, :sender, apikey.sender)
                {true, conn}
            _ -> {false, conn}
        end

        if is_authenticated do
            conn
        else
            conn
            |> send_resp(401, "Unauthorised")
            |> halt
        end
    end
end