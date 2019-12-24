defmodule SmsServer.Repo.Migrations.CreateApikey do
  use Ecto.Migration

  def change do
    create table(:apikey) do
      add :client, :string, null: false
      add :sender, :string, null: false
      add :key, :string, null: false

      timestamps()
    end
  end
end
