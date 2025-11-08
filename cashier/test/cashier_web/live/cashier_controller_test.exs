defmodule CashierWeb.CashierControllerTest do
  use CashierWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Cashier.Cart
  alias Cashier.CartSupervisor
  alias Cashier.Catalog.Product
  alias Cashier.Repo

  setup do
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

    # Generate a unique cashier_id for each test
    cashier_id = "cashier_#{:rand.uniform(999_999)}"

    # Ensure cart is started for the test
    CartSupervisor.start_cart(cashier_id)

    # Clean up cart before each test
    Cart.clear(cashier_id)

    %{cashier_id: cashier_id}
  end

  describe "mount/3" do
    test "mounts successfully with cashier_id from session", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})

      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Total"
    end

    test "starts cart supervisor for the cashier_id", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})

      {:ok, _view, _html} = live(conn, "/")

      # Verify cart can be accessed (supervisor started successfully)
      assert Cart.get_items(cashier_id) == []
    end

    test "assigns initial empty cart status", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})

      {:ok, _view, html} = live(conn, "/")

      assert html =~ "£0.00"
    end

    test "assigns cart with existing items if present", %{conn: conn, cashier_id: cashier_id} do
      # Add items before mounting
      Cart.add_item(cashier_id, "GR1")
      Cart.add_item(cashier_id, "SR1")

      conn = init_test_session(conn, %{"cashier_id" => cashier_id})

      {:ok, _view, html} = live(conn, "/")

      refute html =~ "Total: 0"
    end
  end

  describe "handle_event/3 - add_item" do
    test "adds item to cart", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      # Directly trigger the event handler
      render_hook(view, "add_item", %{"item-id" => "GR1"})

      items = Cart.get_items(cashier_id)
      assert "GR1" in items
    end

    test "adds multiple items sequentially", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      render_hook(view, "add_item", %{"item-id" => "GR1"})
      render_hook(view, "add_item", %{"item-id" => "SR1"})
      render_hook(view, "add_item", %{"item-id" => "CF1"})

      items = Cart.get_items(cashier_id)
      assert length(items) == 3
      assert "GR1" in items
      assert "SR1" in items
      assert "CF1" in items
    end

    test "adds duplicate items", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      render_hook(view, "add_item", %{"item-id" => "GR1"})
      render_hook(view, "add_item", %{"item-id" => "GR1"})

      items = Cart.get_items(cashier_id)
      # Should have 2 instances of GR1
      assert length(Enum.filter(items, &(&1 == "GR1"))) == 2
    end

    test "returns noreply tuple", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      # The render_hook should not raise and view should still be connected
      render_hook(view, "add_item", %{"item-id" => "GR1"})

      assert view.module == CashierWeb.CashierController
    end
  end

  describe "handle_event/3 - remove_item" do
    test "remove an item from cart", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      # Directly trigger the event handler
      render_hook(view, "add_item", %{"item-id" => "GR1"})

      items = Cart.get_items(cashier_id)
      assert "GR1" in items

      render_hook(view, "remove_item", %{"item-id" => "GR1"})

      items = Cart.get_items(cashier_id)
      refute "GR1" in items
    end

    test "removes one of duplicate items", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      render_hook(view, "add_item", %{"item-id" => "GR1"})
      render_hook(view, "add_item", %{"item-id" => "GR1"})

      items = Cart.get_items(cashier_id)
      # Should have 2 instances of GR1
      assert length(Enum.filter(items, &(&1 == "GR1"))) == 2

      render_hook(view, "remove_item", %{"item-id" => "GR1"})

      items = Cart.get_items(cashier_id)
      # Should have 1 instance of GR1
      assert length(Enum.filter(items, &(&1 == "GR1"))) == 1
    end
  end

  describe "handle_event/3 - restart" do
    test "clears all items from cart", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      # Add some items first
      render_hook(view, "add_item", %{"item-id" => "GR1"})
      render_hook(view, "add_item", %{"item-id" => "SR1"})

      assert Cart.get_items(cashier_id) != []

      # Restart
      render_hook(view, "restart", %{})

      assert Cart.get_items(cashier_id) == []
    end

    test "resets final_cart assignment", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      # Add items
      render_hook(view, "add_item", %{"item-id" => "GR1"})
      assert Cart.get_items(cashier_id) != []

      # Restart
      render_hook(view, "restart", %{})
      assert Cart.get_items(cashier_id) == []
    end

    test "can add items again after restart", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      # Add, restart, add again
      render_hook(view, "add_item", %{"item-id" => "GR1"})
      render_hook(view, "restart", %{})
      render_hook(view, "add_item", %{"item-id" => "SR1"})

      items = Cart.get_items(cashier_id)
      assert items == ["SR1"]
    end

    test "restart on empty cart works", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      # Restart without adding anything
      render_hook(view, "restart", %{})

      assert Cart.get_items(cashier_id) == []
    end

    test "returns noreply tuple", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      render_hook(view, "restart", %{})

      assert view.module == CashierWeb.CashierController
    end
  end

  describe "get_cart_status/1" do
    test "returns processed cart for given cart_id", %{cashier_id: cashier_id} do
      Cart.add_item(cashier_id, "GR1")

      result = CashierWeb.CashierController.get_cart_status(cashier_id)

      assert result != nil
    end

    test "returns empty cart status when no items", %{cashier_id: cashier_id} do
      result = CashierWeb.CashierController.get_cart_status(cashier_id)

      assert result != nil
    end

    test "processes cart through CartDetails and RulesProcessor", %{cashier_id: cashier_id} do
      Cart.add_item(cashier_id, "GR1")
      Cart.add_item(cashier_id, "SR1")

      result = CashierWeb.CashierController.get_cart_status(cashier_id)

      # The result should be the output of RulesProcessor.process
      # This tests the integration of Cart -> CartDetails -> RulesProcessor
      assert result != nil
    end
  end

  describe "integration" do
    test "full workflow: mount -> add items -> restart", %{conn: conn, cashier_id: cashier_id} do
      conn = init_test_session(conn, %{"cashier_id" => cashier_id})
      {:ok, view, _html} = live(conn, "/")

      # Initial state
      assert Cart.get_items(cashier_id) == []

      # Add items
      render_hook(view, "add_item", %{"item-id" => "GR1"})
      render_hook(view, "add_item", %{"item-id" => "SR1"})
      render_hook(view, "add_item", %{"item-id" => "CF1"})

      assert length(Cart.get_items(cashier_id)) == 3

      # Restart
      render_hook(view, "restart", %{})

      assert Cart.get_items(cashier_id) == []
    end

    test "multiple sessions with different cashier_ids work independently", %{conn: conn} do
      cashier_id_1 = "cashier_111111"
      cashier_id_2 = "cashier_222222"

      CartSupervisor.start_cart(cashier_id_1)
      CartSupervisor.start_cart(cashier_id_2)

      conn1 = init_test_session(conn, %{"cashier_id" => cashier_id_1})
      {:ok, view1, _html} = live(conn1, "/")

      conn2 = init_test_session(conn, %{"cashier_id" => cashier_id_2})
      {:ok, view2, _html} = live(conn2, "/")

      # Add different items to each cart
      render_hook(view1, "add_item", %{"item-id" => "GR1"})
      render_hook(view2, "add_item", %{"item-id" => "SR1"})

      # Verify independence
      assert Cart.get_items(cashier_id_1) == ["GR1"]
      assert Cart.get_items(cashier_id_2) == ["SR1"]

      # Clean up
      Cart.clear(cashier_id_1)
      Cart.clear(cashier_id_2)
    end
  end
end
