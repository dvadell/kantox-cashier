defmodule Cashier.CartDetails do
  @moduledoc """
  Provides a Cart with detailed information about items 
  """

  alias Cashier.Catalog.Product
  alias Cashier.Repo
  import Ecto.Query

  defstruct items: []

  @typedoc """
  A cart item with full product details and quantity
  """
  @type detail_cart_item :: %{
          code: String.t(),
          name: String.t(),
          price: Decimal.t(),
          units: non_neg_integer()
        }

  @type t :: %__MODULE__{
          items: list(detail_cart_item())
        }

  @doc """
  Creates a CartDetails struct from a list of product codes.

  This function takes a list of product codes (potentially with duplicates),
  queries the database for product information, and returns a %CartDetails struct
  with more data.

  ## Parameters

    - `product_codes` - A list of product codes from a cart (e.g., `["GR1", "GR1", "ABC"]`)

  ## Returns

    - `{:ok, %CartDetails{}}` - Successfully created CartDetails with hydrated items
    - `{:error, :not_found, missing_codes}` - Some products were not found in the database

  ## Examples

      iex> Cashier.Cart.get_items("cashier_123") |> Cashier.CartDetails.new()
      {:ok, %Cashier.CartDetails{
        items: [
          %{code: "GR1", name: "Green Tea", price: Decimal.new("3.11"), units: 2},
          %{code: "ABC", name: "Apple", price: Decimal.new("5.00"), units: 1}
        ]
      }}

      iex> Cashier.CartDetails.new(["GR1", "INVALID"])
      {:error, :not_found, ["INVALID"]}
  """
  @spec new(list(String.t())) :: {:ok, t()} | {:error, :not_found, list(String.t())}
  def new(product_codes) when is_list(product_codes) do
    # Count occurrences of each product code
    num_items = Enum.frequencies(product_codes)
    unique_codes = Map.keys(num_items)

    # Query database for all unique product codes
    product_details =
      from(p in Product,
        where: p.code in ^unique_codes,
        select: %{code: p.code, name: p.name, price: p.price}
      )
      |> Repo.all()
      |> Map.new(&{&1.code, &1})

    # Check if all products were found
    found_codes = Map.keys(product_details)
    missing_codes = unique_codes -- found_codes

    if Enum.empty?(missing_codes) do
      # Finally build cart items with product details from the database
      # and units from the cart.
      items =
        Enum.map(unique_codes, fn code ->
          product = Map.get(product_details, code)

          %{
            code: product.code,
            name: product.name,
            price: product.price,
            units: Map.get(num_items, code)
          }
        end)

      {:ok, %__MODULE__{items: items}}
    else
      # There shouldn't be missing codes! This is clearly a bug...
      {:error, :not_found, missing_codes}
    end
  end
end
