defmodule PowAssent.Test.NoRegistration.Phoenix.Router do
  @moduledoc false
  use Phoenix.Router, helpers: false
  use Pow.Phoenix.Router
  use PowAssent.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    pow_routes()
    pow_assent_authorization_routes()
  end
end
