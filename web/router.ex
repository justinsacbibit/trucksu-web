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
      get "/osu-getreplay.php", ReplayController, :show

      post "/osu-submit-modular.php", ScoreController, :create
      post "/osu-screenshot.php", ScreenshotController, :create

      get "/status", OsuWebController, :status
    end

    scope "/pages" do
      post "/include/home-ircfeed.php", OsuPagesController, :irc_feed
    end

    get "/ss/:id", ScreenshotController, :show
  end

  # The following calls go to a.ppy.sh
  scope "/a", Trucksu do
    get "/:user_id", AvatarController, :show
  end

  scope "/api", Trucksu do
    pipe_through :api

    scope "v1" do
      post "/registrations", RegistrationController, :create
      post "/sessions", SessionController, :create
      delete "/sessions", SessionController, :delete
      get "/current-user", CurrentUserController, :show

      get "/ranks", RanksController, :index
      get "/pp-calc", PerformanceController, :calculate
    end
  end

  scope "/", Trucksu do
    get "/ss/:id", ScreenshotController, :show
  end

  # Frontend
  scope "/", Trucksu do
    pipe_through :browser

    get "*path", PageController, :index
  end
end
