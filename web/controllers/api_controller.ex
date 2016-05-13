defmodule Trucksu.ApiController do
  use Trucksu.Web, :controller

  def not_found(conn, _) do
    conn |> put_status(404) |> json(%{error: "not_found"})
  end
end
