defmodule CashierWeb.CashierController do
  use CashierWeb, :live_view

  alias Cashier.CartSupervisor
  alias Cashier.Cart
  alias Cashier.CartDetails
  alias Cashier.RulesProcessor

  def mount(_params, _session, socket) do
    # DMV: exists?
    cart_id = "cashier_123"
    Cashier.CartSupervisor.start_cart(cart_id)
    {:ok, assign(socket, :final_cart, get_cart_status(cart_id))}
  end

  # ADD an item
  def handle_event("add_item", %{"item-id" => item_id}, socket) do
    cart_id = "cashier_123"
    Cart.add_item(cart_id, item_id)
    final_cart = get_cart_status(cart_id)
    socket = assign(socket, :final_cart, final_cart)
    {:noreply, socket}
  end

  # The RESTART button
  def handle_event("restart", _params, socket) do
    cart_id = "cashier_123"
    Cart.clear(cart_id)
    final_cart = get_cart_status(cart_id)
    socket = assign(socket, :final_cart, final_cart)
    {:noreply, socket}
  end

  def get_cart_status(cart_id) do
    with cart_items <- Cashier.Cart.get_items(cart_id),
         {:ok, cart_details} <- Cashier.CartDetails.new(cart_items),
         {:ok, final_cart} <- Cashier.RulesProcessor.process(cart_details) do
      IO.inspect(final_cart)
      final_cart
    end
  end
end
