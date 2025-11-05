defmodule Cashier.Repo.Migrations.CreateRules do
  use Ecto.Migration

  def change do
    create table(:rules) do
      add :name, :string, null: false
      add :code, :string, null: false
      add :description, :text, null: false
      add :rule_type, :string, null: false
      add :config, :map, default: %{}
      add :conditions, :map, default: %{}
      add :priority, :integer, default: 0
      add :active, :boolean, default: true, null: false
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
