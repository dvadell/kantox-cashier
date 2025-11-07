defmodule Cashier.RulesProcessorTest do
  use Cashier.DataCase

  alias Cashier.CartDetails
  alias Cashier.Catalog.Rule
  alias Cashier.FinalCart
  alias Cashier.Repo
  alias Cashier.RulesProcessor

  describe "process/1" do
    test "returns FinalCart struct with original items marked as :user" do
      cart_details = %CartDetails{
        items: [
          %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 1}
        ]
      }

      {:ok, %FinalCart{items: items}} = RulesProcessor.process(cart_details)

      assert length(items) == 1
      assert List.first(items).source == :user
    end

    test "handles empty cart" do
      cart_details = %CartDetails{items: []}

      {:ok, %FinalCart{items: items}} = RulesProcessor.process(cart_details)

      assert items == []
    end

    test "applies all matching rules from database" do
      # Create a BOGO rule in database
      %Rule{}
      |> Rule.changeset(%{
        name: "Test BOGO",
        code: "TEST_BOGO",
        rule_type: "BOGO",
        description: "A BOGO promotion!",
        config: %{},
        conditions: %{"product_code" => "GR1"}
      })
      |> Repo.insert!()

      cart_details = %CartDetails{
        items: [
          %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 2}
        ]
      }

      {:ok, %FinalCart{items: items}} = RulesProcessor.process(cart_details)

      # Should have original + free item
      assert length(items) == 2
      user_items = Enum.filter(items, &(&1.source == :user))
      rule_items = Enum.filter(items, &(&1.source == :rule))

      assert length(user_items) == 1
      assert length(rule_items) == 1
    end

    test "Let it fail when plugin module doesn't exist" do
      # Create a rule with non-existent plugin
      %Rule{}
      |> Rule.changeset(%{
        name: "Invalid Rule",
        code: "INVALID",
        rule_type: "NONEXISTENT_TYPE",
        description: "Non-existent promotion",
        config: %{},
        conditions: %{"product_code" => "GR1"}
      })
      |> Repo.insert!()

      cart_details = %CartDetails{
        items: [
          %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 2}
        ]
      }

      {:ok, final_cart} = RulesProcessor.process(cart_details)
      [final_cart_items] = final_cart.items
      [cart_details_items] = cart_details.items

      assert final_cart_items.units == cart_details_items.units
      assert final_cart_items.price == cart_details_items.price
    end

    test "processes multiple rules in sequence" do
      # Create multiple rules
      %Rule{}
      |> Rule.changeset(%{
        name: "BOGO",
        code: "BOGO_1",
        rule_type: "BOGO",
        description: "A BOGO promotion!",
        config: %{},
        conditions: %{"product_code" => "GR1"}
      })
      |> Repo.insert!()

      %Rule{}
      |> Rule.changeset(%{
        name: "Bulk",
        code: "BULK_1",
        rule_type: "BULK_DISCOUNT",
        config: %{"price" => "4.50"},
        description: "A Bulk discount promotion!",
        conditions: %{"product_code" => "SR1", "min_quantity" => 3}
      })
      |> Repo.insert!()

      cart_details = %CartDetails{
        items: [
          %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 2},
          %{code: "SR1", name: "Strawberries", price: Decimal.new("5.00"), units: 3}
        ]
      }

      {:ok, %FinalCart{items: items}} = RulesProcessor.process(cart_details)

      assert length(items) == 3

      # Check strawberry price was updated
      strawberry = Enum.find(items, &(&1.code == "SR1"))
      assert Decimal.equal?(strawberry.price, Decimal.new("4.50"))
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
