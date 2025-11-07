defmodule Cashier.Rule.BOGOTest do
  use Cashier.DataCase

  alias Cashier.Catalog.Rule
  alias Cashier.Rule.BOGO

  describe "apply/2" do
    test "adds free items for even quantities" do
      rule = %Rule{
        rule_type: "BOGO",
        config: %{},
        conditions: %{"product_code" => "GR1"}
      }

      items = [
        %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 2, source: :user}
      ]

      result = BOGO.apply(items, rule)

      assert length(result) == 2

      free_item = Enum.find(result, &(&1.source == :rule))
      assert free_item.code == "GR1"
      assert free_item.units == 2
      assert Decimal.equal?(free_item.price, Decimal.new("0"))
    end

    test "returns unchanged items when product not in cart" do
      rule = %Rule{
        rule_type: "BOGO",
        config: %{},
        conditions: %{"product_code" => "GR1"}
      }

      items = [
        %{code: "SR1", name: "Strawberries", price: Decimal.new("5.00"), units: 2, source: :user}
      ]

      result = BOGO.apply(items, rule)

      assert result == items
    end

    test "only applies to user-source items, not rule-source items" do
      rule = %Rule{
        rule_type: "BOGO",
        config: %{},
        conditions: %{"product_code" => "GR1"}
      }

      items = [
        %{code: "GR1", name: "Green tea", price: Decimal.new("0"), units: 2, source: :rule}
      ]

      result = BOGO.apply(items, rule)

      # Should not add more free items for already-free items
      assert result == items
    end

    test "handles large quantities correctly" do
      rule = %Rule{
        rule_type: "BOGO",
        config: %{},
        conditions: %{"product_code" => "GR1"}
      }

      items = [
        %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 10, source: :user}
      ]

      result = BOGO.apply(items, rule)

      free_item = Enum.find(result, &(&1.source == :rule))
      assert free_item.units == 10
    end

    test "handles empty items list" do
      rule = %Rule{
        rule_type: "BOGO",
        config: %{},
        conditions: %{"product_code" => "GR1"}
      }

      items = []

      result = BOGO.apply(items, rule)

      assert result == []
    end
  end
end
