# Assignment

You’re the lead developer for a supermarket chain. Your job is to design and build the first version of a cashier service that provides a feature for managing a shopping carts, applying pricing rules, and computing the final total.

Once your work is complete, three additional team members will join you to refine and enhance the project. However, the expectation is that your version should be production-ready.

# Approach

Every time that a cashier adds or removes a product, the following code is ran:

```
with cart_items <- Cashier.Cart.get_items(cart_id),
     {:ok, cart_details } <- Cashier.CartDetails.new(cart_items),
     {:ok, final_cart} <- Cashier.RulesProcessor.process(cart_details) do
  render(final_cart)
end
```

Let's go through the modules involved in this workflow

## Cashier.Cart

This is a simple GenServer with a :one_to_one DynamicSupervisor, defined in `lib/cashier/cart.ex`. Each cart is identified by a cashier_id and is registered in the global CartRegistry. It stores only the list of items that the user adds to the cart. Example:

```
iex(1)> alias Cashier.Cart
Cashier.Cart
iex(2)> Cashier.CartSupervisor.start_cart("cashier_123")
{:ok, #PID<0.344.0>}
iex(3)> Cart.add_item("cashier_123", "GR1")
:ok
iex(4)> Cart.add_item("cashier_123", "CF1")
:ok
iex(5)> Cart.get_items("cashier_123")
["GR1", "CF1"]
iex(6)> Cart.remove("cashier_123")
:ok
iex(7)> Cashier.Cart.exists?("cashier_123")
false
```

## Cashier.CartDetails

This module would get a list of items and "hydrate" them with their details ( name and price ) from the database.

```
iex(1)> alias Cashier.CartDetails
Cashier.CartDetails
iex(3)> Cashier.CartDetails.new(["GR1", "CF1", "CF1"])
[debug] QUERY OK source="products" db=0.5ms idle=453.1ms
SELECT p0."code", p0."name", p0."price" FROM "products" AS p0 WHERE (p0."code" = ANY($1)) [["CF1", "GR1"]]
↳ Cashier.CartDetails.new/1, at: lib/cashier/cart_details.ex:67
{:ok,
 %Cashier.CartDetails{
   items: [
     %{code: "CF1", name: "Coffee", price: Decimal.new("11.23"), units: 2},
     %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 1}
   ]
 }}
```

## Cashier.RulesProcessor

This module is the orchestrator or engine of your pricing rules system. It's the central module that takes a cart with items and applies all the promotional rules to calculate the final pricing.

The Cashier application includes a flexible, plugin-based rules system that allows you to apply dynamic pricing strategies to carts. Rules as configuration are stored in the database and processed through registered plugins (see `config/config.exs`).

### Cashier.RulePlugin

Each rule plugin implements the `Cashier.RulePlugin` behavior and processes cart items independently. The `RulesProcessor` queries only active rules that have registered plugins, optimizing database performance by filtering inactive or unsupported rules. Rules are applied sequentially based on their priority, allowing you to control the order of operations when multiple promotions affect the same products. The final cart includes all original items (marked with `source: :user`) plus any items added by rules (marked with `source: :rule`), such as free items from BOGO promotions.

To add a new rule type, create a module that implements the `Cashier.RulePlugin` behavior with an `apply/2` function, then register it in your `config/config.exs` under the `:plugins` key. The system automatically discovers and applies rules based on their `rule_type` field matching your plugin configuration. Rules can be activated, deactivated, or re-prioritized directly in the database without requiring application restarts.

### Available Rule Plugins

* Buy One Get One (BOGO)

**Example Configuration:**
```
%{
  rule_type: "BOGO",
  config: %{},
  conditions: %{"product_code" => "GR1"}
}
```

* Bulk Discount

**Example Configuration:**
```
%{
  rule_type: "BULK_DISCOUNT",
  config: %{"price" => "4.50"},
  conditions: %{"product_code" => "SR1", "min_quantity" => 3}
}
```

* Fractional Price

**Example Configuration:**
```
%{
  rule_type: "FRACTIONAL_PRICE",
  config: %{"price_fraction" => 0.66666},  # 2/3 of original price
  conditions: %{"product_code" => "CF1", "min_quantity" => 3}
}
```


# Future 
* Consider using Horde for production clusters
* Add a timeout to orphan Carts
* Add telemetry
