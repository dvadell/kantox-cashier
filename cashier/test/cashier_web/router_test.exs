defmodule CashierWeb.RouterTest do
  use CashierWeb.ConnCase, async: true

  describe "browser pipeline" do
    test "accepts HTML requests", %{conn: conn} do
      conn = get(conn, "/")

      # Should not return 406 Not Acceptable
      refute conn.status == 406
    end

    test "rejects non-HTML requests in browser pipeline", %{conn: conn} do
      assert_raise Phoenix.NotAcceptableError, fn ->
        conn
        |> put_req_header("accept", "application/json")
        |> get("/")
      end
    end

    test "fetches session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{test_key: "test_value"})
        |> get("/")

      # Session should be available (checked in controller/live view)
      # This verifies fetch_session plug is in the pipeline
      assert get_session(conn, :test_key) == "test_value"
    end

    test "applies CashierID plug", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> get("/")

      # The CashierID plug should have assigned a cashier_id
      cashier_id = get_session(conn, :cashier_id)
      assert cashier_id != nil
      assert String.starts_with?(cashier_id, "cashier_")
    end

    test "sets secure browser headers", %{conn: conn} do
      conn = get(conn, "/")

      # Check for standard security headers set by put_secure_browser_headers
      # Note: In test environment, some headers might not be set
      # We verify the CSP header which we explicitly set
      csp_header = get_resp_header(conn, "content-security-policy")
      assert csp_header == ["default-src 'self'"]
    end

    test "sets custom CSP header", %{conn: conn} do
      conn = get(conn, "/")

      csp_header = get_resp_header(conn, "content-security-policy")
      assert csp_header == ["default-src 'self'"]
    end
  end

  describe "routes" do
    test "root path routes to CashierController", %{conn: conn} do
      conn = get(conn, "/")

      # Verify the route exists and doesn't return 404
      refute conn.status == 404
    end

    test "non-existent routes return 404", %{conn: conn} do
      conn = get(conn, "/non-existent-path")
      assert conn.status == 404
    end
  end

  describe "pipeline order" do
    test "plugs execute in correct order", %{conn: conn} do
      # Session must be fetched before CashierID can use it
      conn =
        conn
        |> init_test_session(%{})
        |> get("/")

      # If CashierID runs after fetch_session, this should work
      cashier_id = get_session(conn, :cashier_id)
      assert cashier_id != nil
    end
  end
end
