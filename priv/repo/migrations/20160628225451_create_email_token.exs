defmodule Trucksu.Repo.Migrations.CreateEmailToken do
  use Ecto.Migration

  def change do
    create table(:email_tokens) do
      add :token, :string, null: false, size: 20
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps
    end
    create index(:email_tokens, [:user_id])

  end
end
