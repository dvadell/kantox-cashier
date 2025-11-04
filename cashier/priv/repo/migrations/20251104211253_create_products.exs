defmodule Cashier.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :code, :string, null: false
      add :name, :string, null: false
      add :price, :decimal, precision: 10, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
