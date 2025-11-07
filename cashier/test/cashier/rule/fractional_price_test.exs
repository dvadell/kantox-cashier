defmodule Cashier.Rule.FractionalPriceTest do
  use Cashier.DataCase

  alias Cashier.Catalog.Rule
  alias Cashier.Rule.FractionalPrice

  describe "apply/2" do
    test "applies fractional price when minimum quantity met" do
      rule = %Rule{
        rule_type: "FRACTIONAL_PRICE",
        config: %{"price_fraction" => 0.66666},
        conditions: %{"product_code" => "CF1", "min_quantity" => 3}
      }

      items = [
        %{code: "CF1", name: "Coffee", price: Decimal.new("5.00"), units: 3, source: :user}
      ]

      result = FractionalPrice.apply(items, rule)

      assert length(result) == 1
      item = List.first(result)

      # 5.00 * 0.66666 = 3.3333
      expected_price = Decimal.mult(Decimal.new("5.00"), Decimal.from_float(0.66666))
      assert Decimal.equal?(item.price, expected_price)
    end

    test "applies fractional price when quantity exceeds minimum" do
      rule = %Rule{
        rule_type: "FRACTIONAL_PRICE",
        config: %{"price_fraction" => 0.66666},
        conditions: %{"product_code" => "CF1", "min_quantity" => 3}
      }

      items = [
        %{code: "CF1", name: "Coffee", price: Decimal.new("5.00"), units: 5, source: :user}
      ]

      result = FractionalPrice.apply(items, rule)

      item = List.first(result)
      expected_price = Decimal.mult(Decimal.new("5.00"), Decimal.from_float(0.66666))
      assert Decimal.equal?(item.price, expected_price)
    end

    test "doesn't apply when below minimum quantity" do
      rule = %Rule{
        rule_type: "FRACTIONAL_PRICE",
        config: %{"price_fraction" => 0.66666},
        conditions: %{"product_code" => "CF1", "min_quantity" => 3}
      }

      items = [
        %{code: "CF1", name: "Coffee", price: Decimal.new("5.00"), units: 2, source: :user}
      ]

      result = FractionalPrice.apply(items, rule)

      item = List.first(result)
      assert Decimal.equal?(item.price, Decimal.new("5.00"))
    end

    test "doesn't apply to wrong product code" do
      rule = %Rule{
        rule_type: "FRACTIONAL_PRICE",
        config: %{"price_fraction" => 0.66666},
        conditions: %{"product_code" => "CF1", "min_quantity" => 3}
      }

      items = [
        %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 5, source: :user}
      ]

      result = FractionalPrice.apply(items, rule)

      item = List.first(result)
      assert Decimal.equal?(item.price, Decimal.new("3.11"))
    end

    test "only applies to user-source items" do
      rule = %Rule{
        rule_type: "FRACTIONAL_PRICE",
        config: %{"price_fraction" => 0.66666},
        conditions: %{"product_code" => "CF1", "min_quantity" => 3}
      }

      items = [
        %{code: "CF1", name: "Coffee", price: Decimal.new("5.00"), units: 3, source: :rule}
      ]

      result = FractionalPrice.apply(items, rule)

      item = List.first(result)
      assert Decimal.equal?(item.price, Decimal.new("5.00"))
    end

    test "handles multiple items, only affects matching one" do
      rule = %Rule{
        rule_type: "FRACTIONAL_PRICE",
        config: %{"price_fraction" => 0.66666},
        conditions: %{"product_code" => "CF1", "min_quantity" => 3}
      }

      items = [
        %{code: "CF1", name: "Coffee", price: Decimal.new("5.00"), units: 3, source: :user},
        %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 3, source: :user}
      ]

      result = FractionalPrice.apply(items, rule)

      coffee = Enum.find(result, &(&1.code == "CF1"))
      green_tea = Enum.find(result, &(&1.code == "GR1"))

      expected_coffee_price = Decimal.mult(Decimal.new("5.00"), Decimal.from_float(0.66666))
      assert Decimal.equal?(coffee.price, expected_coffee_price)
      assert Decimal.equal?(green_tea.price, Decimal.new("3.11"))
    end

    test "handles empty items list" do
      rule = %Rule{
        rule_type: "FRACTIONAL_PRICE",
        config: %{"price_fraction" => 0.66666},
        conditions: %{"product_code" => "CF1", "min_quantity" => 3}
      }

      items = []

      result = FractionalPrice.apply(items, rule)

      assert result == []
    end

    test "handles different fractional values" do
      rule = %Rule{
        rule_type: "FRACTIONAL_PRICE",
        config: %{"price_fraction" => 0.5},
        conditions: %{"product_code" => "CF1", "min_quantity" => 3}
      }

      items = [
        %{code: "CF1", name: "Coffee", price: Decimal.new("10.00"), units: 3, source: :user}
      ]

      result = FractionalPrice.apply(items, rule)

      item = List.first(result)
      assert Decimal.equal?(item.price, Decimal.new("5.00"))
    end

    test "handles exact minimum quantity" do
      rule = %Rule{
        rule_type: "FRACTIONAL_PRICE",
        config: %{"price_fraction" => 0.66666},
        conditions: %{"product_code" => "CF1", "min_quantity" => 3}
      }

      items = [
        %{code: "CF1", name: "Coffee", price: Decimal.new("5.00"), units: 3, source: :user}
      ]

      result = FractionalPrice.apply(items, rule)

      item = List.first(result)
      expected_price = Decimal.mult(Decimal.new("5.00"), Decimal.from_float(0.66666))
      assert Decimal.equal?(item.price, expected_price)
    end
  end
end
