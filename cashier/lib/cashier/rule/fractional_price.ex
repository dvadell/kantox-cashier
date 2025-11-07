defmodule Cashier.Rule.FractionalPrice do
  @moduledoc """
  Fractional price rule.

  If you buy a minimum quantity, the price will be multiplied by a fraction
  """

  @behaviour Cashier.RulePlugin

  @impl true
  def apply(items, rule) do
    product_code = rule.conditions["product_code"]
    min_quantity = rule.conditions["min_quantity"]
    price_fraction = rule.config["price_fraction"]

    # Update the price if conditions are met
    Enum.map(items, fn item ->
      if item.code == product_code && item.source == :user && item.units >= min_quantity do
        new_price = Decimal.mult(item.price, Decimal.from_float(price_fraction))
        %{item | price: new_price}
      else
        item
      end
    end)
  end
end
