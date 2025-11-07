defmodule Cashier.RulesProcessor do
  @moduledoc """
  Processes cart items through pricing rules and returns a final cart.

  This is the engine that runs all rule plugins!
  """

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
    # Get all rules from database
    # DMV: where rule_name in [ ... ] and active == true order by priority.
    rules_config = Repo.all(Rule)

    # Get plugin configuration
    plugins = Application.get_env(:cashier, __MODULE__)[:plugins] || %{}

    # Items added by the user have source: :user to distinguish them from
    # the items added by the rules
    original_items = Enum.map(items, &Map.put(&1, :source, :user))

    # Process each rule
    final_items =
      Enum.reduce(rules_config, original_items, fn rule, acc_items ->
        apply_rule(rule, acc_items, plugins)
      end)

    {:ok, %FinalCart{items: final_items}}
  end

  # Apply a single rule to the cart items
  defp apply_rule(rule, items, plugins) do
    # Get the plugin module for this rule type
    plugin_module = Map.get(plugins, rule.rule_type)

    # Fail hard here if there is a misconfiguration.
    plugin_module.apply(items, rule)
  end
end
