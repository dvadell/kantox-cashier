defmodule Cashier.FinalCartTest do
  use ExUnit.Case

  alias Cashier.FinalCart

  describe "FinalCart struct" do
    test "can be created with items" do
      final_cart = %FinalCart{
        items: [
          %{code: "GR1", name: "Green tea", price: Decimal.new("3.11"), units: 1, source: :user}
        ]
      }

      assert length(final_cart.items) == 1
    end

    test "can be created empty" do
      final_cart = %FinalCart{items: []}

      assert final_cart.items == []
    end

    test "has default empty items list" do
      final_cart = %FinalCart{}

      assert final_cart.items == []
    end
  end
end
