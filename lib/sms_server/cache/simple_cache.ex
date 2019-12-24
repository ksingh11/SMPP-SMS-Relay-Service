defmodule SmsServer.SimpleCache do
    use GenServer
    require Logger

    alias CacheMoney.Adapters.ETS
    
    def start_link(_args) do
        Logger.debug("Starting SimpleCache genserver")
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end

    def init(_args) do
        CacheMoney.start_link(:my_cache, %{adapter: ETS})
    end

    def set(key, val, ttl\\nil) do
        GenServer.call(__MODULE__, {:set, key, val, ttl})
    end

    def get(key) do
        GenServer.call(__MODULE__, {:get, key})
    end

    def handle_call({:set, key, val, ttl}, _from, cache) do
        res = CacheMoney.set(cache, key, val, ttl)
        {:reply, :ok, cache}
    end

    def handle_call({:get, key}, _from, cache) do
        val = CacheMoney.get(cache, key)
        {:reply, val, cache}
    end
end