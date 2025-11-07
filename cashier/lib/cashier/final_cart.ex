defmodule Cashier.FinalCart do
  @moduledoc """
  Represents the final cart after all rules have been applied.
  No functions, just a struct.
  """

  defstruct items: []

  @type t :: %__MODULE__{
          items: list(map())
        }
end
