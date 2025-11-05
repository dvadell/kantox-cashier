defmodule Cashier.Catalog.Rule do
  @moduledoc """
  Schema for rules
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "rules" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :rule_type, :string
    field :config, :map
    field :conditions, :map
    field :priority, :integer
    field :active, :boolean, default: true
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [
      :name,
      :code,
      :description,
      :rule_type,
      :config,
      :conditions,
      :priority,
      :active,
      :start_date,
      :end_date
    ])
    |> validate_required([:name, :code, :description, :rule_type])
  end
end
