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

This is a simple GenServer with a :one_to_one Supervisor, defined in `lib/cashier/cart.ex`. Each cart is identified by a cashier_id and is registered in the global CartRegistry. It stores only the a list of items that the user adds to the cart. Example:

```
iex(1)> alias Cashier.Cart
Cashier.Cart
iex(2)> Cart.start_link(cashier_id: "cashier_123")
{:ok, #PID<0.344.0>}
iex(3)> Cart.add_item("cashier_123", "GR1")
:ok
iex(4)> Cart.add_item("cashier_123", "CF1")
:ok
iex(5)> Cart.get_items("cashier_123")
["GR1", "CF1"]


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






# Future 
* Consider using Horde for production clusters
