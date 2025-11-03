defmodule CashierWeb.Router do
  use CashierWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CashierWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # We have no API for now
  #  pipeline :api do
  #    plug :accepts, ["json"]
  #  end

  scope "/", CashierWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", CashierWeb do
  #   pipe_through :api
  # end
end
