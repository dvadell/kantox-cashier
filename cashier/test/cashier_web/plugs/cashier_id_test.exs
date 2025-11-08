defmodule CashierWeb.Plugs.CashierIDTest do
  use CashierWeb.ConnCase, async: true

  alias CashierWeb.Plugs.CashierID

  describe "init/1" do
    test "returns the options unchanged" do
      opts = %{some: :option}
      assert CashierID.init(opts) == opts
    end
  end

  describe "call/2" do
    test "assigns a cashier_id when session doesn't have one", %{conn: conn} do
      conn = conn |> init_test_session(%{})
      conn = CashierID.call(conn, [])

      cashier_id = get_session(conn, :cashier_id)
      assert cashier_id != nil
      assert String.starts_with?(cashier_id, "cashier_")
    end

    test "generates cashier_id with proper format", %{conn: conn} do
      conn = conn |> init_test_session(%{})
      conn = CashierID.call(conn, [])

      cashier_id = get_session(conn, :cashier_id)
      assert String.match?(cashier_id, ~r/^cashier_\d{6}$/)
    end

    test "does not override existing cashier_id", %{conn: conn} do
      existing_id = "cashier_123456"
      conn = conn |> init_test_session(%{cashier_id: existing_id})
      conn = CashierID.call(conn, [])

      cashier_id = get_session(conn, :cashier_id)
      assert cashier_id == existing_id
    end

    test "preserves other session data", %{conn: conn} do
      conn = conn |> init_test_session(%{user_id: 42, other_data: "test"})
      conn = CashierID.call(conn, [])

      assert get_session(conn, :user_id) == 42
      assert get_session(conn, :other_data) == "test"
      assert get_session(conn, :cashier_id) != nil
    end

    test "generates unique IDs on multiple calls", %{conn: conn} do
      conn1 = conn |> init_test_session(%{})
      conn1 = CashierID.call(conn1, [])
      id1 = get_session(conn1, :cashier_id)

      conn2 = conn |> init_test_session(%{})
      conn2 = CashierID.call(conn2, [])
      id2 = get_session(conn2, :cashier_id)

      # While not guaranteed to be different, in practice they should be
      # This test might occasionally fail due to random collision
      assert id1 != id2
    end

    test "cashier_id has 6 digits with leading zeros", %{conn: conn} do
      # Run multiple times to increase chance of getting a low number
      ids =
        Enum.map(1..20, fn _ ->
          conn = conn |> init_test_session(%{})
          conn = CashierID.call(conn, [])
          get_session(conn, :cashier_id)
        end)

      # All IDs should have exactly 6 digits after "cashier_"
      Enum.each(ids, fn id ->
        [_prefix, number] = String.split(id, "_")
        assert String.length(number) == 6
      end)
    end
  end
end
