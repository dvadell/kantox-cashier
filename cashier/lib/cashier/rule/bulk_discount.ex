defmodule Cashier.Rule.BulkDiscount do
  @moduledoc """
  Bulk discount rule.
  If you buy a minimum quantity, the price will drop to a special price
  """

  @behaviour Cashier.RulePlugin

  @impl true
  def apply(items, rule) do
    product_code = rule.conditions["product_code"]
    min_quantity = rule.conditions["min_quantity"]
    new_price = Decimal.new(rule.config["price"])

    # Update the price if conditions are met
    Enum.map(items, fn item ->
      if item.code == product_code && item.source == :user && item.units >= min_quantity do
        %{item | price: new_price}
      else
        item
      end
    end)
  end
end
