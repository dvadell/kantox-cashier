defmodule Cashier.CartDetailsTest do
  use Cashier.DataCase, async: true

  alias Cashier.CartDetails
  alias Cashier.Catalog.Product

  describe "new/1" do
    setup do
      # Create test products
      {:ok, green_tea} =
        %Product{}
        |> Product.changeset(%{
          code: "GR1",
          name: "Green Tea",
          price: Decimal.new("3.11")
        })
        |> Repo.insert()

      {:ok, strawberries} =
        %Product{}
        |> Product.changeset(%{
          code: "SR1",
          name: "Strawberries",
          price: Decimal.new("5.00")
        })
        |> Repo.insert()

      {:ok, coffee} =
        %Product{}
        |> Product.changeset(%{
          code: "CF1",
          name: "Coffee",
          price: Decimal.new("11.23")
        })
        |> Repo.insert()

      %{
        green_tea: green_tea,
        strawberries: strawberries,
        coffee: coffee
      }
    end

    test "creates CartDetails with single item", %{green_tea: green_tea} do
      product_codes = ["GR1"]

      assert {:ok, %CartDetails{items: items}} = CartDetails.new(product_codes)
      assert length(items) == 1

      [item] = items
      assert item.code == green_tea.code
      assert item.name == green_tea.name
      assert Decimal.equal?(item.price, green_tea.price)
      assert item.units == 1
    end

    test "creates CartDetails with multiple different items", %{
      green_tea: green_tea,
      strawberries: strawberries
    } do
      product_codes = ["GR1", "SR1"]

      assert {:ok, %CartDetails{items: items}} = CartDetails.new(product_codes)
      assert length(items) == 2

      items_by_code = Map.new(items, &{&1.code, &1})

      assert items_by_code["GR1"].name == green_tea.name
      assert Decimal.equal?(items_by_code["GR1"].price, green_tea.price)
      assert items_by_code["GR1"].units == 1

      assert items_by_code["SR1"].name == strawberries.name
      assert Decimal.equal?(items_by_code["SR1"].price, strawberries.price)
      assert items_by_code["SR1"].units == 1
    end

    test "creates CartDetails with duplicate items and counts units correctly", %{
      green_tea: green_tea
    } do
      product_codes = ["GR1", "GR1", "GR1"]

      assert {:ok, %CartDetails{items: items}} = CartDetails.new(product_codes)
      assert length(items) == 1

      [item] = items
      assert item.code == green_tea.code
      assert item.units == 3
    end

    test "creates CartDetails with mixed duplicate and unique items", %{
      green_tea: green_tea,
      strawberries: strawberries,
      coffee: coffee
    } do
      product_codes = ["GR1", "SR1", "GR1", "CF1", "SR1", "SR1"]

      assert {:ok, %CartDetails{items: items}} = CartDetails.new(product_codes)
      assert length(items) == 3

      items_by_code = Map.new(items, &{&1.code, &1})

      assert items_by_code["GR1"].units == 2
      assert items_by_code["SR1"].units == 3
      assert items_by_code["CF1"].units == 1

      assert items_by_code["GR1"].name == green_tea.name
      assert items_by_code["SR1"].name == strawberries.name
      assert items_by_code["CF1"].name == coffee.name
    end

    test "returns error when product code does not exist" do
      product_codes = ["INVALID"]

      assert {:error, :not_found, missing_codes} = CartDetails.new(product_codes)
      assert "INVALID" in missing_codes
    end

    test "returns error with multiple missing product codes" do
      product_codes = ["INVALID1", "INVALID2", "INVALID3"]

      assert {:error, :not_found, missing_codes} = CartDetails.new(product_codes)
      assert length(missing_codes) == 3
      assert "INVALID1" in missing_codes
      assert "INVALID2" in missing_codes
      assert "INVALID3" in missing_codes
    end

    test "returns error when some products exist and some don't" do
      product_codes = ["GR1", "INVALID"]

      assert {:error, :not_found, missing_codes} = CartDetails.new(product_codes)
      assert "INVALID" in missing_codes
      assert length(missing_codes) == 1
    end

    test "returns error even when invalid code appears multiple times" do
      product_codes = ["INVALID", "INVALID", "INVALID"]

      assert {:error, :not_found, missing_codes} = CartDetails.new(product_codes)
      assert "INVALID" in missing_codes
      # Should only return unique missing codes
      assert length(missing_codes) == 1
    end

    test "handles empty list of product codes" do
      product_codes = []

      assert {:ok, %CartDetails{items: items}} = CartDetails.new(product_codes)
      assert items == []
    end

    test "preserves decimal precision in prices", %{coffee: coffee} do
      product_codes = ["CF1"]

      assert {:ok, %CartDetails{items: [item]}} = CartDetails.new(product_codes)
      assert Decimal.equal?(item.price, Decimal.new("11.23"))
      assert item.price == coffee.price
    end

    test "handles large quantities correctly", %{green_tea: green_tea} do
      # Create a list with 100 of the same item
      product_codes = List.duplicate("GR1", 100)

      assert {:ok, %CartDetails{items: [item]}} = CartDetails.new(product_codes)
      assert item.code == green_tea.code
      assert item.units == 100
    end

    test "handles all products in database" do
      product_codes = ["GR1", "SR1", "CF1"]

      assert {:ok, %CartDetails{items: items}} = CartDetails.new(product_codes)
      assert length(items) == 3

      codes = Enum.map(items, & &1.code) |> Enum.sort()
      assert codes == ["CF1", "GR1", "SR1"]
    end

    test "returns CartDetails struct with correct type" do
      product_codes = []

      assert {:ok, cart_details} = CartDetails.new(product_codes)
      assert %CartDetails{} = cart_details
      assert is_list(cart_details.items)
    end

    test "cart items have all required fields" do
      product_codes = ["GR1"]

      assert {:ok, %CartDetails{items: [item]}} = CartDetails.new(product_codes)

      # Verify all required fields exist
      assert Map.has_key?(item, :code)
      assert Map.has_key?(item, :name)
      assert Map.has_key?(item, :price)
      assert Map.has_key?(item, :units)

      # Verify field types
      assert is_binary(item.code)
      assert is_binary(item.name)
      assert %Decimal{} = item.price
      assert is_integer(item.units)
      assert item.units >= 0
    end

    test "handles products with special characters in names" do
      {:ok, special_product} =
        %Product{}
        |> Product.changeset(%{
          code: "SP1",
          name: "Café São Paulo (Premium)",
          price: Decimal.new("15.50")
        })
        |> Repo.insert()

      product_codes = ["SP1"]

      assert {:ok, %CartDetails{items: [item]}} = CartDetails.new(product_codes)
      assert item.name == "Café São Paulo (Premium)"
      assert item.code == special_product.code
    end

    test "query is case-sensitive for product codes", %{green_tea: _green_tea} do
      # GR1 exists, but gr1 (lowercase) should not be found
      product_codes = ["gr1"]

      assert {:error, :not_found, missing_codes} = CartDetails.new(product_codes)
      assert "gr1" in missing_codes
    end

    test "handles whitespace in product codes correctly" do
      # Product codes with whitespace should not match existing products
      product_codes = [" GR1", "GR1 ", " GR1 "]

      assert {:error, :not_found, missing_codes} = CartDetails.new(product_codes)
      assert length(missing_codes) == 3
    end
  end
end
