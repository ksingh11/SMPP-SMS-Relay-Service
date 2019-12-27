defmodule DB.ApiKey do
    use Ecto.Schema
    alias SmsServer.Repo

    schema "apikey" do
        field :client, :string
        field :sender, :string
        field :key, :string

        timestamps()
    end

    def test_fixture() do
        Repo.insert %DB.ApiKey{client: "zostel", sender: "ZOSTEL", key: "hello123"}
    end

    def get_client_data(client_name) do
        Repo.get_by(DB.ApiKey, client: client_name)
    end
end