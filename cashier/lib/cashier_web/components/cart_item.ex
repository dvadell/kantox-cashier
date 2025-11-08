defmodule CashierWeb.Components.CartItem do
  @moduledoc """
  A component that renders a cart item
  """
  use Phoenix.Component

  attr :item, :map, required: true

  def cart_item(assigns) do
    ~H"""
    <div class="bg-white p-4 shadow-sm border border-gray-200">
      <div class="flex justify-between items-center">
        <div class="flex-1">
          <h3 class="text-gray-800">{@item.name}</h3>
          <p class="text-sm text-gray-500">
            <span
              class="border border-gray-300 px-[5px] cursor-pointer hover:bg-gray-100"
              phx-click="remove_item"
              phx-value-item-id={@item.code}
            >
              -
            </span>
            <span class="border border-gray-300 px-[5px]">{@item.units}</span>
            <span
              class="border border-gray-300 px-[5px] cursor-pointer hover:bg-gray-100"
              phx-click="add_item"
              phx-value-item-id={@item.code}
            >
              +
            </span>
          </p>
        </div>
        <div class="flex-1 text-center">
          <p class="font-bold text-gray-900">£{Decimal.round(@item.price, 2)}</p>
        </div>
        <div class="text-right">
          <p class="font-bold text-gray-900">
            £{Decimal.round(@item.price, 2) |> Decimal.mult(@item.units)}
          </p>
        </div>
      </div>
    </div>
    """
  end
end
