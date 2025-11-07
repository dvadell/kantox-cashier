defmodule Cashier.RulesProcessor do
  @moduledoc """
  Processes cart items through pricing rules and returns a final cart.

  This is the engine that runs all rule plugins!
  """

  import Ecto.Query

  alias Cashier.CartDetails
  alias Cashier.Catalog.Rule
  alias Cashier.FinalCart
  alias Cashier.Repo

  @doc """
  Processes cart details through all applicable rules.

      A bit of terminology
      * A Rule or Rule config is an entry in the database (or potentially elsewhere) that would configure a Rule plugin to apply some change to the user's cart.
      * A Plugin or Rule plugin is code that takes a Rule config and applies some transformation to the user's cart
      * A Final Cart is the final version of a user's cart, with all the information to be displayed.

      In pseudo-elixir:
      {Rule config, Cart} |> Rule Plugins |> %FinalCart{}

  ## Example
      iex> {:ok, cart_details} = ["GR1", "GR1"] |> Cashier.CartDetails.new()
      iex> RulesProcessor.process(cart_details)
      {:ok, %FinalCart{...}}

  """
  def process(%CartDetails{items: items}) do
    # Get plugin configuration
    plugins = Application.get_env(:cashier, __MODULE__)[:plugins] || %{}

    # We may rules that have no plugin capable of managing them (like old promotions)
    existing_rule_types = Map.keys(plugins)

    # Get the rules by priority, only active rules
    rules_config =
      Rule
      |> where([r], r.rule_type in ^existing_rule_types)
      |> where([r], r.active == true)
      |> order_by([r], asc: r.priority)
      |> Repo.all()

    # Items added by the user have source: :user to distinguish them from
    # the items added by the rules
    original_items = Enum.map(items, &Map.put(&1, :source, :user))

    # Process each rule
    final_items =
      Enum.reduce(rules_config, original_items, fn rule, acc_items ->
        apply_rule(rule, acc_items, plugins)
      end)

    # Calculate (sub)total
    acc = Decimal.new("0")

    total =
      final_items
      |> Enum.reduce(acc, fn item, acc ->
        Decimal.add(
          acc,
          Decimal.mult(Decimal.new(item.units), item.price)
        )
      end)

    {:ok, %FinalCart{items: final_items, total: total}}
  end

  # Apply a single rule to the cart items
  defp apply_rule(rule, items, plugins) do
    # Get the plugin module for this rule type
    plugin_module = Map.get(plugins, rule.rule_type)

    # Fail hard here if there is a misconfiguration.
    plugin_module.apply(items, rule)
  end
end
