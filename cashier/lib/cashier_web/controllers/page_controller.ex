defmodule CashierWeb.PageController do
  use CashierWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
