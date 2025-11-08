defmodule Cashier.Repo.Migrations.AddIndicesToRules do
  use Ecto.Migration

  def change do
    # Composite index for the WHERE clause filters + ORDER BY
    create index(:rules, [:active, :rule_type, :priority], name: :rules_active_type_priority_idx)
  end
end
