defmodule Cashier.RulesProcessorTest do
  use Cashier.DataCase

  alias Cashier.CartDetails
  alias Cashier.FinalCart
  alias Cashier.RulesProcessor

  describe "process/1" do
    test "returns FinalCart struct with original items marked as :user" do
      cart_details = %CartDetails{
        items: [
          %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 1}
        ]
      }

      {:ok, %FinalCart{items: items, total: total}} = RulesProcessor.process(cart_details)

      assert length(items) == 2
      assert List.first(items).source == :user
      assert total == Decimal.new("3.11")
    end

    test "handles empty cart" do
      cart_details = %CartDetails{items: []}

      {:ok, %FinalCart{items: items, total: total}} = RulesProcessor.process(cart_details)

      assert items == []
      assert total == Decimal.new("0")
    end

    test "applies all matching rules from database" do
      cart_details = %CartDetails{
        items: [
          %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 2}
        ]
      }

      {:ok, %FinalCart{items: items, total: total}} = RulesProcessor.process(cart_details)

      # Should have original + free item
      assert length(items) == 2
      user_items = Enum.filter(items, &(&1.source == :user))
      rule_items = Enum.filter(items, &(&1.source == :rule))

      assert length(user_items) == 1
      assert length(rule_items) == 1
      assert total == Decimal.new("6.22")
    end

    test "processes multiple rules in sequence" do
      cart_details = %CartDetails{
        items: [
          %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 2},
          %{code: "SR1", name: "Strawberries", price: Decimal.new("5.00"), units: 3}
        ]
      }

      {:ok, %FinalCart{items: items, total: total}} = RulesProcessor.process(cart_details)

      assert length(items) == 3

      # Check strawberry price was updated
      strawberry = Enum.find(items, &(&1.code == "SR1"))
      assert Decimal.equal?(strawberry.price, Decimal.new("4.50"))
      assert total == Decimal.new("19.72")
    end

    test "handles configuration with empty plugins map" do
      # Temporarily override config
      original_config = Application.get_env(:cashier, RulesProcessor)
      Application.put_env(:cashier, RulesProcessor, plugins: %{})

      cart_details = %CartDetails{
        items: [
          %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 1}
        ]
      }

      {:ok, %FinalCart{items: items}} = RulesProcessor.process(cart_details)

      # Should return items unchanged
      assert length(items) == 1
      assert List.first(items).source == :user

      # Restore config
      Application.put_env(:cashier, RulesProcessor, original_config)
    end
  end
end
