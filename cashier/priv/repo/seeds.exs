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
