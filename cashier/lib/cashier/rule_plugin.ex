defmodule Cashier.RulePlugin do
  @moduledoc """
  Behaviour for pricing rules that apply discounts to a cart.
  """

  @doc """
  Applies the pricing rule to a cart.
  """
  @callback apply(items :: list(map()), rule :: Cashier.Catalog.Rule.t()) :: list(map())
end
