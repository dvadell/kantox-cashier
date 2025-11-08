defmodule CashierWeb.CashierController do
  use CashierWeb, :live_view

  alias Cashier.CartSupervisor
  alias Cashier.Cart
  alias Cashier.CartDetails
  alias Cashier.RulesProcessor

  def mount(_params, _session, socket) do
    # DMV: exists?
    cart_id = "cashier_123"
    Cashier.CartSupervisor.start_cart("cashier_123")

    with cart_items <- Cashier.Cart.get_items(cart_id),
         {:ok, cart_details } <- Cashier.CartDetails.new(cart_items),
         {:ok, final_cart} <- Cashier.RulesProcessor.process(cart_details) do
             IO.inspect(final_cart)
             {:ok, assign(socket, :final_cart, final_cart)}
    end

  end
end
