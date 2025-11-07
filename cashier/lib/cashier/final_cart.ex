defmodule Cashier.FinalCart do
  @moduledoc """
  Represents the final cart after all rules have been applied.
  No functions, just a struct.
  """

  defstruct items: [], total: Decimal.new("0")

  @type t :: %__MODULE__{
          items: list(map()),
          total: Decimal.t()
        }
end
