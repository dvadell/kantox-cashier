defmodule CashierWeb.CashierController do
  use CashierWeb, :live_view

  alias Cashier.Cart
  alias Cashier.CartDetails
  alias Cashier.CartSupervisor
  alias Cashier.RulesProcessor

  def mount(_params, session, socket) do
    cashier_id = session["cashier_id"]
    CartSupervisor.start_cart(cashier_id)

    socket =
      socket
      |> assign(:cashier_id, cashier_id)
      |> assign(:final_cart, get_cart_status(cashier_id))

    {:ok, socket}
  end

  # ADD an item
  def handle_event("add_item", %{"item-id" => item_id}, socket) do
    cashier_id = socket.assigns.cashier_id
    Cart.add_item(cashier_id, item_id)
    socket = assign(socket, :final_cart, get_cart_status(cashier_id))

    {:noreply, socket}
  end

  # The RESTART button
  def handle_event("restart", _params, socket) do
    cashier_id = socket.assigns.cashier_id
    Cart.clear(cashier_id)
    final_cart = get_cart_status(cashier_id)
    socket = assign(socket, :final_cart, final_cart)

    {:noreply, socket}
  end

  def get_cart_status(cart_id) do
    with cart_items <- Cart.get_items(cart_id),
         {:ok, cart_details} <- CartDetails.new(cart_items),
         {:ok, final_cart} <- RulesProcessor.process(cart_details) do
      final_cart
    end
  end
end
