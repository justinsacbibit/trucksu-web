defmodule Trucksu.GroupController do
  use Trucksu.Web, :controller
  alias Trucksu.{
    Group,
  }

  plug :find_group when action in [:show]

  defp find_group(conn, _) do
    group = Repo.get! Group, conn.params["id"]
    assign(conn, :group, group)
  end

  def index(conn, _params) do
    groups = Repo.all Group
    render(conn, "index.json", groups: groups)
  end

  def show(conn, _params) do
    group = conn.assigns[:group] |> Repo.preload(:users)
    render(conn, "show.json", group: group)
  end
end

