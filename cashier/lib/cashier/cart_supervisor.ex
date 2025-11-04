defmodule Cashier.CartSupervisor do
  @moduledoc """
  DynamicSupervisor for managing Cart GenServers.
  """
  use DynamicSupervisor

  @type user_id :: String.t()

  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Starts a new cart for the given cashier_id.

  ## Examples

      iex> Cashier.CartSupervisor.start_cart("cashier_123")
      {:ok, #PID<0.123.0>}
  """
  @spec start_cart(user_id()) :: DynamicSupervisor.on_start_child()
  def start_cart(cashier_id) do
    spec = {Cashier.Cart, cashier_id: cashier_id}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  @spec init(term()) :: {:ok, DynamicSupervisor.sup_flags()}
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
