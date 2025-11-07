defmodule Cashier.Rule.BulkDiscountTest do
  use Cashier.DataCase

  alias Cashier.Catalog.Rule
  alias Cashier.Rule.BulkDiscount

  describe "apply/2" do
    test "applies discount when minimum quantity met" do
      rule = %Rule{
        rule_type: "BULK_DISCOUNT",
        config: %{"price" => "4.50"},
        conditions: %{"product_code" => "SR1", "min_quantity" => 3}
      }

      items = [
        %{code: "SR1", name: "Strawberries", price: Decimal.new("5.00"), units: 3, source: :user}
      ]

      result = BulkDiscount.apply(items, rule)

      assert length(result) == 1
      item = List.first(result)
      assert Decimal.equal?(item.price, Decimal.new("4.50"))
    end

    test "applies discount when quantity exceeds minimum" do
      rule = %Rule{
        rule_type: "BULK_DISCOUNT",
        config: %{"price" => "4.50"},
        conditions: %{"product_code" => "SR1", "min_quantity" => 3}
      }

      items = [
        %{code: "SR1", name: "Strawberries", price: Decimal.new("5.00"), units: 5, source: :user}
      ]

      result = BulkDiscount.apply(items, rule)

      item = List.first(result)
      assert Decimal.equal?(item.price, Decimal.new("4.50"))
    end

    test "doesn't apply discount when below minimum quantity" do
      rule = %Rule{
        rule_type: "BULK_DISCOUNT",
        config: %{"price" => "4.50"},
        conditions: %{"product_code" => "SR1", "min_quantity" => 3}
      }

      items = [
        %{code: "SR1", name: "Strawberries", price: Decimal.new("5.00"), units: 2, source: :user}
      ]

      result = BulkDiscount.apply(items, rule)

      item = List.first(result)
      assert Decimal.equal?(item.price, Decimal.new("5.00"))
    end

    test "doesn't apply to wrong product code" do
      rule = %Rule{
        rule_type: "BULK_DISCOUNT",
        config: %{"price" => "4.50"},
        conditions: %{"product_code" => "SR1", "min_quantity" => 3}
      }

      items = [
        %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 5, source: :user}
      ]

      result = BulkDiscount.apply(items, rule)

      item = List.first(result)
      assert Decimal.equal?(item.price, Decimal.new("3.11"))
    end

    test "only applies to user-source items" do
      rule = %Rule{
        rule_type: "BULK_DISCOUNT",
        config: %{"price" => "4.50"},
        conditions: %{"product_code" => "SR1", "min_quantity" => 3}
      }

      items = [
        %{code: "SR1", name: "Strawberries", price: Decimal.new("5.00"), units: 3, source: :rule}
      ]

      result = BulkDiscount.apply(items, rule)

      item = List.first(result)
      # Price should remain unchanged for rule-source items
      assert Decimal.equal?(item.price, Decimal.new("5.00"))
    end

    test "handles multiple items, only affects matching one" do
      rule = %Rule{
        rule_type: "BULK_DISCOUNT",
        config: %{"price" => "4.50"},
        conditions: %{"product_code" => "SR1", "min_quantity" => 3}
      }

      items = [
        %{code: "SR1", name: "Strawberries", price: Decimal.new("5.00"), units: 3, source: :user},
        %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 3, source: :user}
      ]

      result = BulkDiscount.apply(items, rule)

      strawberry = Enum.find(result, &(&1.code == "SR1"))
      green_tea = Enum.find(result, &(&1.code == "GR1"))

      assert Decimal.equal?(strawberry.price, Decimal.new("4.50"))
      assert Decimal.equal?(green_tea.price, Decimal.new("3.11"))
    end

    test "handles empty items list" do
      rule = %Rule{
        rule_type: "BULK_DISCOUNT",
        config: %{"price" => "4.50"},
        conditions: %{"product_code" => "SR1", "min_quantity" => 3}
      }

      items = []

      result = BulkDiscount.apply(items, rule)

      assert result == []
    end

    test "handles exact minimum quantity" do
      rule = %Rule{
        rule_type: "BULK_DISCOUNT",
        config: %{"price" => "4.50"},
        conditions: %{"product_code" => "SR1", "min_quantity" => 3}
      }

      items = [
        %{code: "SR1", name: "Strawberries", price: Decimal.new("5.00"), units: 3, source: :user}
      ]

      result = BulkDiscount.apply(items, rule)

      item = List.first(result)
      assert Decimal.equal?(item.price, Decimal.new("4.50"))
    end
  end
end
