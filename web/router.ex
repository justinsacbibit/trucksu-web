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
    plug Trucksu.Plug.IncrementStat, name: "api.requests"
  end

  pipeline :screenshots do
    plug Trucksu.Plug.IncrementStat, name: "screenshots.requests"
  end

  pipeline :avatars do
    plug Trucksu.Plug.IncrementStat, name: "avatars.requests"
  end

  pipeline :osu_ppy do
    plug Trucksu.Plug.IncrementStat, name: "osu.ppy.requests"
  end

  scope "/", Trucksu do
  end

  # ss.trucksu.com
  scope "/ss", Trucksu do
    pipe_through :screenshots

    get "/:id", ScreenshotController, :show
  end

  # The following calls go to osu.ppy.sh
  scope "/osu", Trucksu do
    pipe_through :osu_ppy

    scope "/web" do
      get "/bancho_connect.php", OsuWebController, :bancho_connect
      get "/osu-osz2-getscores.php", OsuWebController, :get_scores
      get "/osu-search-set.php", OsuWebController, :search_set
      post "/osu-metrics.php", OsuWebController, :osu_metrics
      get "/check-updates.php", OsuWebController, :check_updates
      get "/lastfm.php", OsuWebController, :lastfm
      get "/osu-getreplay.php", ReplayController, :show
      get "/maps/:filename", OsuWebController, :show_map
      get "/osu-search.php", OsuDirectController, :direct_index

      post "/osu-error.php", OsuWebController, :screenshot

      post "/osu-submit-modular.php", ScoreController, :create
      post "/osu-screenshot.php", ScreenshotController, :create
    end

    scope "/pages" do
      post "/include/home-ircfeed.php", OsuPagesController, :irc_feed
    end

    get "/ss/:id", ScreenshotController, :show
    get "/d/:beatmapset_id", OszController, :download
    get "/u/:user_id", UserController, :show_osu_user

    get "/forum/ucp.php", UserController, :show_osu_user

    # beatmap page
    get "/b/:beatmap_id", OsuBeatmapPageController, :show_beatmap
    get "/s/:beatmapset_id", OsuBeatmapPageController, :show_beatmapset

    get "/*path", ApiController, :redirect_to_trucksu
  end

  # The following calls go to a.ppy.sh
  scope "/a", Trucksu do
    pipe_through :avatars

    get "/:user_id", AvatarController, :show
  end

  # api.trucksu.com
  scope "/api", Trucksu do
    pipe_through :api

    scope "/v1" do
      post "/registrations", RegistrationController, :create
      post "/verify-email", RegistrationController, :verify_email
      post "/resend-verification-email", UserController, :resend_verification_email
      post "/sessions", SessionController, :create
      delete "/sessions", SessionController, :delete
      get "/current-user", CurrentUserController, :show

      get "/ranks", RanksController, :index
      get "/pp-calc", PerformanceController, :calculate

      scope "/users" do
        get "/:id", UserController, :show

        # admin
        patch "/:id_or_username", UserController, :patch
      end

      scope "/groups" do
        get "/:id", GroupController, :show
        get "/", GroupController, :index
      end

      scope "/me" do
        post "/avatar", UserController, :upload_avatar
      end

      scope "/beatmaps" do
        get "/:beatmap_id", OsuBeatmapController, :show
      end

      scope "/beatmapsets" do
        get "/", OsuBeatmapsetController, :index
        get "/:beatmapset_id/download", OszController, :download
      end

      # admin endpoints
      post "/ban", UserController, :ban
      delete "/ban", UserController, :unban
      get "/users/:id_or_username/multis", UserController, :multiaccounts

      post "/bancho-events", BanchoEventController, :create
    end

    get "/*path", ApiController, :not_found
  end
end
