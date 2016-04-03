defmodule Trucksu.Router do
  use Trucksu.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  scope "/", Trucksu do
    # pipe_through :api
  end

  # The following calls go to osu.ppy.sh
  scope "/osu", Trucksu do
    scope "/web" do
      get "/bancho_connect.php", OsuWebController, :bancho_connect
      get "/osu-osz2-getscores.php", OsuWebController, :get_scores
      post "/osu-metrics.php", OsuWebController, :osu_metrics
      get "/check-updates.php", OsuWebController, :check_updates
      get "/lastfm.php", OsuWebController, :lastfm

      post "/osu-submit-modular.php", ScoreController, :create
    end

    scope "/api" do
      pipe_through :api

      scope "v1" do
        post "/registrations", RegistrationController, :create
        post "/sessions", SessionController, :create
        delete "/sessions", SessionController, :delete
        get "/current-user", CurrentUserController, :show
      end
    end

    scope "/" do
      pipe_through :browser

      get "*path", PageController, :index
    end
  end

  # The following calls go to a.ppy.sh
  scope "/a", Trucksu do
    get "/:user_id", AvatarController, :show
  end

  # The following calls go to c.ppy.sh or c1.ppy.sh
  scope "/c", Trucksu do
    post "/", TrucksuController, :index
  end

  # Internal API calls
  scope "/ops", Trucksu do
    post "restart", OpsController, :restart
  end
end
