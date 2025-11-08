defmodule CashierWeb.Plugs.CashierID do
  @moduledoc """
  A plug that assigns a unique cashier_id to each browser session.
  If the session doesn't have a cashier_id, one is generated and stored.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :cashier_id) do
      nil ->
        cashier_id = generate_cashier_id()
        put_session(conn, :cashier_id, cashier_id)

      _cashier_id ->
        conn
    end
  end

  defp generate_cashier_id do
    random_number = :rand.uniform(999_999)
    padded_number = random_number |> Integer.to_string() |> String.pad_leading(6, "0")
    "cashier_#{padded_number}"
  end
end
