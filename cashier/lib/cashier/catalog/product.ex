defmodule Cashier.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :code, :string
    field :name, :string
    field :price, :decimal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:code, :name, :price])
    |> validate_required([:code, :name, :price])
    |> validate_number(:price, greater_than: 0)
  end
end
