defmodule Trucksu.Repo.Migrations.CreateGroup do
  use Ecto.Migration

  def up do
    create table(:groups) do
      add :name, :string, null: false
    end

    execute "INSERT INTO groups (id, name) VALUES (1, 'Trucksu Team')"
    execute "INSERT INTO groups (id, name) VALUES (2, 'Global Moderation Team')"
    execute "INSERT INTO groups (id, name) VALUES (3, 'Development Team')"
  end

  def down do
    drop table(:groups)
  end
end
