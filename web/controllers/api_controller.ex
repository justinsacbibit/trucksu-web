defmodule Trucksu.ApiController do
  use Trucksu.Web, :controller

  def redirect_to_trucksu(conn, _) do
    website_url = Application.get_env(:trucksu, :website_url)
    redirect conn, external: "#{website_url}"
  end

  def not_found(conn, _) do
    conn |> put_status(404) |> json(%{error: "not_found"})
  end
end
