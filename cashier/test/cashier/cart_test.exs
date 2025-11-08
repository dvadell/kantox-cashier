defmodule Cashier.CartTest do
  use ExUnit.Case, async: false

  alias Cashier.Cart
  alias Cashier.CartSupervisor

  setup do
    # Generate unique cashier_id for each test to avoid conflicts
    cashier_id = "cashier_#{:erlang.unique_integer([:positive])}"

    # Clean up any existing cart for this cashier
    if Cart.exists?(cashier_id) do
      Cart.remove(cashier_id)
    end

    {:ok, cashier_id: cashier_id}
  end

  describe "start_link/1" do
    test "starts a cart with a cashier_id", %{cashier_id: cashier_id} do
      assert {:ok, pid} = Cart.start_link(cashier_id: cashier_id)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "registers the cart globally with cashier_id", %{cashier_id: cashier_id} do
      {:ok, _pid} = Cart.start_link(cashier_id: cashier_id)

      # Verify it's registered
      assert Cart.exists?(cashier_id)
    end

    test "returns error when starting duplicate cart for same cashier_id", %{
      cashier_id: cashier_id
    } do
      {:ok, _pid} = Cart.start_link(cashier_id: cashier_id)

      # Attempting to start another cart with same cashier_id should fail
      assert {:error, {:already_started, _pid}} = Cart.start_link(cashier_id: cashier_id)
    end

    test "raises when cashier_id is not provided" do
      assert_raise KeyError, fn ->
        Cart.start_link([])
      end
    end
  end

  describe "add_item/2" do
    setup %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      :ok
    end

    test "adds a product code to the cart", %{cashier_id: cashier_id} do
      assert :ok = Cart.add_item(cashier_id, "GR1")
      assert ["GR1"] = Cart.get_items(cashier_id)
    end

    test "adds multiple items to the cart", %{cashier_id: cashier_id} do
      assert :ok = Cart.add_item(cashier_id, "GR1")
      assert :ok = Cart.add_item(cashier_id, "SR1")
      assert :ok = Cart.add_item(cashier_id, "CF1")

      assert ["GR1", "SR1", "CF1"] = Cart.get_items(cashier_id)
    end

    test "adds duplicate items to the cart", %{cashier_id: cashier_id} do
      assert :ok = Cart.add_item(cashier_id, "GR1")
      assert :ok = Cart.add_item(cashier_id, "GR1")
      assert :ok = Cart.add_item(cashier_id, "GR1")

      assert ["GR1", "GR1", "GR1"] = Cart.get_items(cashier_id)
    end
  end

  describe "remove_item/2" do
    setup %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      :ok
    end

    test "removes a product code from the cart", %{cashier_id: cashier_id} do
      assert :ok = Cart.add_item(cashier_id, "GR1")
      assert ["GR1"] = Cart.get_items(cashier_id)
      assert :ok = Cart.remove_item(cashier_id, "GR1")
      assert [] = Cart.get_items(cashier_id)
    end

    test "remove multiple items from the cart", %{cashier_id: cashier_id} do
      assert :ok = Cart.add_item(cashier_id, "GR1")
      assert :ok = Cart.add_item(cashier_id, "SR1")
      assert :ok = Cart.add_item(cashier_id, "CF1")

      assert ["GR1", "SR1", "CF1"] = Cart.get_items(cashier_id)

      assert :ok = Cart.remove_item(cashier_id, "SR1")
      assert :ok = Cart.remove_item(cashier_id, "CF1")

      assert ["GR1"] = Cart.get_items(cashier_id)
    end

    test "removes one of duplicate items from the cart", %{cashier_id: cashier_id} do
      assert :ok = Cart.add_item(cashier_id, "GR1")
      assert :ok = Cart.add_item(cashier_id, "GR1")
      assert :ok = Cart.add_item(cashier_id, "GR1")

      assert ["GR1", "GR1", "GR1"] = Cart.get_items(cashier_id)

      assert :ok = Cart.remove_item(cashier_id, "GR1")

      assert ["GR1", "GR1"] = Cart.get_items(cashier_id)
    end
  end

  describe "get_items/1" do
    setup %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      :ok
    end

    test "returns empty list for new cart", %{cashier_id: cashier_id} do
      assert [] = Cart.get_items(cashier_id)
    end

    test "returns all items in the cart", %{cashier_id: cashier_id} do
      Cart.add_item(cashier_id, "GR1")
      Cart.add_item(cashier_id, "SR1")
      Cart.add_item(cashier_id, "GR1")

      assert ["GR1", "SR1", "GR1"] = Cart.get_items(cashier_id)
    end
  end

  describe "item_counts/1" do
    setup %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      :ok
    end

    test "returns empty map for new cart", %{cashier_id: cashier_id} do
      assert %{} = Cart.item_counts(cashier_id)
    end

    test "returns counts of each product", %{cashier_id: cashier_id} do
      Cart.add_item(cashier_id, "GR1")
      Cart.add_item(cashier_id, "SR1")
      Cart.add_item(cashier_id, "GR1")
      Cart.add_item(cashier_id, "CF1")
      Cart.add_item(cashier_id, "GR1")

      assert %{"GR1" => 3, "SR1" => 1, "CF1" => 1} = Cart.item_counts(cashier_id)
    end

    test "returns correct count for single product type", %{cashier_id: cashier_id} do
      Cart.add_item(cashier_id, "GR1")
      Cart.add_item(cashier_id, "GR1")

      assert %{"GR1" => 2} = Cart.item_counts(cashier_id)
    end
  end

  describe "item_count/1" do
    setup %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      :ok
    end

    test "returns 0 for new cart", %{cashier_id: cashier_id} do
      assert 0 = Cart.item_count(cashier_id)
    end

    test "returns total number of items", %{cashier_id: cashier_id} do
      Cart.add_item(cashier_id, "GR1")
      assert 1 = Cart.item_count(cashier_id)

      Cart.add_item(cashier_id, "SR1")
      assert 2 = Cart.item_count(cashier_id)

      Cart.add_item(cashier_id, "GR1")
      assert 3 = Cart.item_count(cashier_id)
    end
  end

  describe "clear/1" do
    setup %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      :ok
    end

    test "clears all items from cart", %{cashier_id: cashier_id} do
      Cart.add_item(cashier_id, "GR1")
      Cart.add_item(cashier_id, "SR1")
      Cart.add_item(cashier_id, "CF1")

      assert 3 = Cart.item_count(cashier_id)

      assert :ok = Cart.clear(cashier_id)
      assert [] = Cart.get_items(cashier_id)
      assert 0 = Cart.item_count(cashier_id)
    end

    test "clearing empty cart returns ok", %{cashier_id: cashier_id} do
      assert :ok = Cart.clear(cashier_id)
      assert [] = Cart.get_items(cashier_id)
    end

    test "can add items after clearing", %{cashier_id: cashier_id} do
      Cart.add_item(cashier_id, "GR1")
      Cart.clear(cashier_id)

      Cart.add_item(cashier_id, "SR1")
      assert ["SR1"] = Cart.get_items(cashier_id)
    end
  end

  describe "exists?/1" do
    test "returns false when cart doesn't exist", %{cashier_id: cashier_id} do
      refute Cart.exists?(cashier_id)
    end

    test "returns true when cart exists", %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      assert true = Cart.exists?(cashier_id)
    end

    test "returns false after cart is removed", %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      assert true = Cart.exists?(cashier_id)

      Cart.remove(cashier_id)
      refute Cart.exists?(cashier_id)
    end
  end

  describe "remove/1" do
    test "removes an existing cart", %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      Cart.add_item(cashier_id, "GR1")

      assert :ok = Cart.remove(cashier_id)
      refute Cart.exists?(cashier_id)
    end

    test "returns error when cart doesn't exist", %{cashier_id: cashier_id} do
      assert {:error, :not_found} = Cart.remove(cashier_id)
    end

    test "cart cannot be accessed after removal", %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      Cart.remove(cashier_id)

      # Attempting to access removed cart should raise
      assert catch_exit(Cart.get_items(cashier_id))
    end

    test "can create new cart after removal with same cashier_id", %{cashier_id: cashier_id} do
      {:ok, pid1} = CartSupervisor.start_cart(cashier_id)
      Cart.add_item(cashier_id, "GR1")
      Cart.remove(cashier_id)

      {:ok, pid2} = CartSupervisor.start_cart(cashier_id)

      # Should be a different process
      assert pid1 != pid2

      # Should be empty (fresh cart)
      assert [] = Cart.get_items(cashier_id)
    end
  end

  describe "handle_continue/2" do
    test "is called after init with cashier_id", %{cashier_id: cashier_id} do
      # This tests that handle_continue doesn't crash
      # and that the cart initializes properly
      {:ok, pid} = Cart.start_link(cashier_id: cashier_id)

      # Give it a moment to process continue
      Process.sleep(10)

      # Cart should be functional
      assert Process.alive?(pid)
      assert [] = Cart.get_items(cashier_id)
    end
  end

  describe "cart state persistence" do
    setup %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      :ok
    end

    test "maintains state across multiple operations", %{cashier_id: cashier_id} do
      # Add items
      Cart.add_item(cashier_id, "GR1")
      Cart.add_item(cashier_id, "SR1")

      # Check state
      assert 2 = Cart.item_count(cashier_id)

      # Add more
      Cart.add_item(cashier_id, "GR1")

      # State should be updated
      assert 3 = Cart.item_count(cashier_id)
      assert %{"GR1" => 2, "SR1" => 1} = Cart.item_counts(cashier_id)
    end
  end

  describe "concurrent operations" do
    setup %{cashier_id: cashier_id} do
      {:ok, _pid} = CartSupervisor.start_cart(cashier_id)
      :ok
    end

    test "handles concurrent add_item calls", %{cashier_id: cashier_id} do
      # Spawn multiple processes adding items concurrently
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            Cart.add_item(cashier_id, "ITEM_#{rem(i, 3)}")
          end)
        end

      # Wait for all to complete
      Enum.each(tasks, &Task.await/1)

      # Should have 10 items total
      assert 10 = Cart.item_count(cashier_id)
    end
  end

  describe "multiple carts" do
    test "different cashiers have independent carts" do
      cashier1 = "cashier_1_#{:erlang.unique_integer([:positive])}"
      cashier2 = "cashier_2_#{:erlang.unique_integer([:positive])}"

      {:ok, _} = CartSupervisor.start_cart(cashier1)
      {:ok, _} = CartSupervisor.start_cart(cashier2)

      # Add different items to each cart
      Cart.add_item(cashier1, "GR1")
      Cart.add_item(cashier1, "GR1")

      Cart.add_item(cashier2, "SR1")
      Cart.add_item(cashier2, "CF1")
      Cart.add_item(cashier2, "SR1")

      # Verify independence
      assert 2 = Cart.item_count(cashier1)
      assert ["GR1", "GR1"] = Cart.get_items(cashier1)

      assert 3 = Cart.item_count(cashier2)
      assert ["SR1", "CF1", "SR1"] = Cart.get_items(cashier2)

      # Cleanup
      Cart.remove(cashier1)
      Cart.remove(cashier2)
    end
  end
end
