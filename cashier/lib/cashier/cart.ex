defmodule Cashier.Cart do
  @moduledoc """
  A GenServer that manages a shopping cart for a specific cashier.

  Each cart is identified by a cashier_id and is registered in the CartRegistry.
  """
  use GenServer

  defstruct items: []

  @type cashier_id :: String.t()
  @type product_code :: String.t()
  @type t :: %__MODULE__{
          items: list(String.t())
        }

  ##############
  # Client API
  ##############

  @doc """
  Starts a new cart for the given cashier_id.

  ## Examples

      iex> Cashier.Cart.start_link(cashier_id: "cashier_123")
      {:ok, #PID<0.123.0>}
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    cashier_id = Keyword.fetch!(opts, :cashier_id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(cashier_id))
  end

  @doc """
  Adds an item to the cashier's cart.

  ## Examples

      iex> Cashier.Cart.add_item("cashier_123", "GR1")
      :ok
  """
  @spec add_item(cashier_id(), product_code()) :: :ok
  def add_item(cashier_id, product_code) do
    GenServer.call(via_tuple(cashier_id), {:add_item, product_code})
  end

  @doc """
  Returns all items in the cashier's cart.

  ## Examples

      iex> Cashier.Cart.get_items("cashier_123")
      ["GR1", "SR1", "GR1"]
  """
  @spec get_items(cashier_id()) :: list(product_code())
  def get_items(cashier_id) do
    GenServer.call(via_tuple(cashier_id), :get_items)
  end

  @doc """
  Returns a map of product codes and their quantities.

  ## Examples

      iex> Cashier.Cart.item_counts("cashier_123")
      %{"GR1" => 2, "SR1" => 1}
  """
  @spec item_counts(cashier_id()) :: %{product_code() => non_neg_integer()}
  def item_counts(cashier_id) do
    GenServer.call(via_tuple(cashier_id), :item_counts)
  end

  @doc """
  Returns the number of items in the cart.
  """
  @spec item_count(cashier_id()) :: non_neg_integer()
  def item_count(cashier_id) do
    GenServer.call(via_tuple(cashier_id), :item_count)
  end

  @doc """
  Clears all items from the cart.
  """
  @spec clear(cashier_id()) :: :ok
  def clear(cashier_id) do
    GenServer.call(via_tuple(cashier_id), :clear)
  end

  @doc """
  Removes the cart for the given cashier (called after checkout).

  ## Examples

      iex> Cashier.Cart.remove("cashier_123")
      :ok
  """
  @spec remove(cashier_id()) :: :ok | {:error, :not_found}
  def remove(cashier_id) do
    case GenServer.whereis(via_tuple(cashier_id)) do
      nil -> {:error, :not_found}
      pid -> DynamicSupervisor.terminate_child(Cashier.CartSupervisor, pid)
    end
  end

  @doc """
  Checks if a cart exists for the given cashier.
  """
  @spec exists?(cashier_id()) :: boolean()
  def exists?(cashier_id) do
    case GenServer.whereis(via_tuple(cashier_id)) do
      nil -> false
      _pid -> true
    end
  end

  ###################
  # Server Callbacks
  ###################

  @impl true
  @spec init(keyword()) :: {:ok, t()}
  def init(cashier_id: _cashier_id) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  @spec handle_call(
          {:add_item, product_code()},
          GenServer.from(),
          t()
        ) :: {:reply, :ok, t()}
  def handle_call({:add_item, product_code}, _from, %__MODULE__{items: items} = state) do
    new_state = %{state | items: items ++ [product_code]}
    {:reply, :ok, new_state}
  end

  @impl true
  @spec handle_call(:get_items, GenServer.from(), t()) ::
          {:reply, list(product_code()), t()}
  def handle_call(:get_items, _from, %__MODULE__{items: items} = state) do
    {:reply, items, state}
  end

  @impl true
  @spec handle_call(:item_counts, GenServer.from(), t()) ::
          {:reply, %{product_code() => non_neg_integer()}, t()}
  def handle_call(:item_counts, _from, %__MODULE__{items: items} = state) do
    counts = Enum.frequencies(items)
    {:reply, counts, state}
  end

  @impl true
  @spec handle_call(:item_count, GenServer.from(), t()) ::
          {:reply, non_neg_integer(), t()}
  def handle_call(:item_count, _from, %__MODULE__{items: items} = state) do
    {:reply, length(items), state}
  end

  @impl true
  @spec handle_call(:clear, GenServer.from(), t()) :: {:reply, :ok, t()}
  def handle_call(:clear, _from, state) do
    {:reply, :ok, %{state | items: []}}
  end

  # Consider migrating to Horde for production clusters
  defp via_tuple(cashier_id), do: {:global, {:cart, cashier_id}}
end
