defmodule SmsServer.ApiKey do
    use Ecto.Schema
    alias SmsServer.Repo

    schema "apikey" do
        field :client, :string
        field :sender, :string
        field :key, :string

        timestamps()
    end

    def fixture() do
        Repo.insert %SmsServer.ApiKey{client: "zostel", sender: "ZOSTEL", key: "hello123"}
    end

    def get_client_data(client_name) do
        Repo.get_by(SmsServer.ApiKey, client: client_name)
    end
end