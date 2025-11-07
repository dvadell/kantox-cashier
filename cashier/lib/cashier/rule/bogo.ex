defmodule Cashier.Rule.BOGO do
  @moduledoc """
  Buy One Get One Free rule.
  For every unit of a product, add a free second one
  """

  @behaviour Cashier.RulePlugin

  @impl true
  def apply(items, rule) do
    product_code = rule.conditions["product_code"]

    # Find the matching item in the cart. Find the first, because
    # each item is different (two of the same item appear as units: 2)
    item_index =
      Enum.find_index(items, fn item ->
        item.code == product_code && item.source == :user
      end)

    case item_index do
      nil ->
        # Product not in cart, return unchanged
        items

      index ->
        # Find the item
        item = Enum.at(items, index)

        # Create a free item entry
        free_item = %{
          code: item.code,
          name: item.name,
          price: Decimal.new("0"),
          units: item.units,
          source: :rule
        }

        # Add the free item to the cart
        items ++ [free_item]
    end
  end
end
