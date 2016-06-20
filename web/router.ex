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

  # ss.trucksu.com
  scope "/ss", Trucksu do
    get "/:id", ScreenshotController, :show
  end

  # The following calls go to osu.ppy.sh
  scope "/osu", Trucksu do
    scope "/web" do
      get "/bancho_connect.php", OsuWebController, :bancho_connect
      get "/osu-osz2-getscores.php", OsuWebController, :get_scores
      get "/osu-search-set.php", OsuWebController, :search_set
      post "/osu-metrics.php", OsuWebController, :osu_metrics
      get "/check-updates.php", OsuWebController, :check_updates
      get "/lastfm.php", OsuWebController, :lastfm
      get "/osu-getreplay.php", ReplayController, :show
      get "/maps/:filename", OsuWebController, :show_map

      post "/osu-submit-modular.php", ScoreController, :create
      post "/osu-screenshot.php", ScreenshotController, :create

      get "/status", OsuWebController, :status
    end

    scope "/pages" do
      post "/include/home-ircfeed.php", OsuPagesController, :irc_feed
    end

    get "/ss/:id", ScreenshotController, :show
    get "/d/:beatmapset_id", OszController, :download
    get "/u/:user_id", UserController, :show_osu_user

    # beatmap page
    get "/b/:beatmap_id", OsuBeatmapPageController, :show_beatmap
    get "/s/:beatmapset_id", OsuBeatmapPageController, :show_beatmapset
  end

  # The following calls go to a.ppy.sh
  scope "/a", Trucksu do
    get "/:user_id", AvatarController, :show
  end

  # api.trucksu.com
  scope "/api", Trucksu do
    pipe_through :api

    scope "v1" do
      post "/registrations", RegistrationController, :create
      post "/sessions", SessionController, :create
      delete "/sessions", SessionController, :delete
      get "/current-user", CurrentUserController, :show

      get "/ranks", RanksController, :index
      get "/pp-calc", PerformanceController, :calculate
      get "/users/:id", UserController, :show

      scope "/beatmaps" do
        get "/:beatmap_id", OsuBeatmapController, :show
      end

      # admin endpoints
      post "/ban", UserController, :ban
      delete "/ban", UserController, :unban
      get "/users/:id_or_username/multis", UserController, :multiaccounts
    end

    get "*path", ApiController, :not_found
  end

  scope "/ss", Trucksu do
    get "/:id", ScreenshotController, :show
  end
end
