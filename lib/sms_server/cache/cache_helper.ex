defmodule SmsServer.CacheHelper do
    alias SmsServer.SimpleCache
    require Logger

    @cache_ttl 3600 * 1000

    def get_client_data(client_id) do
        case SimpleCache.get(client_id) do
            {:ok, nil} -> 
                Logger.debug("Fetch clientid from DB")
                apikey = SmsServer.ApiKey.get_client_data(client_id)
                if apikey != nil do
                    SimpleCache.set(client_id, apikey, @cache_ttl)
                end
                apikey
            {:ok, apikey} -> 
                Logger.debug("Got client id in Cache #{inspect apikey}")
                apikey
        end
    end
end