defmodule Trucksu.ErrorView do
  use Trucksu.Web, :view

  defp map_errors(errors) do
    errors
    |> Enum.map(fn({key, {message, _}}) -> {key, message} end)
    |> Enum.into(%{})
  end

  def render("400.json", %{reason: %{errors: errors}}) when length(errors) > 0 do
    %{errors: map_errors(errors)}
  end
  def render("400.json", _assigns) do
    %{errors: %{detail: "Bad request"}}
  end

  def render("404.json", %{reason: %{errors: errors}}) when length(errors) > 0 do
    %{errors: map_errors(errors)}
  end
  def render("404.json", _assigns) do
    %{errors: %{detail: "Page not found"}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Server internal error"}}
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.json", assigns
  end
end
