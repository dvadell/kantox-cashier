# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Cashier.Repo.insert!(%Cashier.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Cashier.Repo
alias Cashier.Catalog.Product
alias Cashier.Catalog.Rule

#################
# Product seeds #
#################

# Clear existing products
Repo.delete_all(Product)

# Insert test products
Repo.insert!(%Product{
  code: "GR1",
  name: "Green tea",
  price: Decimal.new("3.11")
})

Repo.insert!(%Product{
  code: "SR1",
  name: "Strawberries",
  price: Decimal.new("5.00")
})

Repo.insert!(%Product{
  code: "CF1",
  name: "Coffee",
  price: Decimal.new("11.23")
})

###############
# Rules seeds #
###############

# Clear existing rules
Repo.delete_all(Rule)

rules = [
  %{
    name: "Green Tea - Buy One Get One",
    code: "GREEN_TEA_BOGO",
    description: "Buy one green tea, get one for free",
    rule_type: "BOGO",
    config: %{},
    conditions: %{
      "product_code" => "GR1"
    }
  },
  %{
    name: "Strawberry Bulk Discount",
    code: "STRAWBERRY_BULK",
    description: "Buy 3 or more strawberries for £4.50 each",
    rule_type: "BULK_DISCOUNT",
    config: %{
      "price" => "4.50"
    },
    conditions: %{
      "product_code" => "SR1",
      "min_quantity" => 3
    }
  },
  %{
    name: "Coffee Bulk Discount",
    code: "COFFEE_BULK",
    description: "Buy 3 or more coffees at 2/3 of the price",
    rule_type: "FRACTIONAL_PRICE",
    config: %{
      "price_fraction" => 0.66666
    },
    conditions: %{
      "product_code" => "CF1",
      "min_quantity" => 3
    }
  }
]

Enum.each(rules, fn rule ->
  %Rule{}
  |> Rule.changeset(rule)
  |> Repo.insert!()
end)
