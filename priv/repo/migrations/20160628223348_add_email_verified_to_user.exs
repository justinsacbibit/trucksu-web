defmodule Trucksu.Repo.Migrations.AddEmailVerifiedToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :email_verified, :boolean
    end

    execute "UPDATE users SET email_verified = false"

    alter table(:users) do
      modify :email_verified, :boolean, null: false
    end
  end

  def down do
    alter table(:users) do
      remove :email_verified
    end
  end
end
