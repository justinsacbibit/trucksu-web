defmodule Trucksu.Countries do
  def country_name(country_code) do
    case Countries.filter_by(:alpha2, country_code) do
      [%{name: name}] ->
        to_string(name)
      _ ->
        nil
    end
  end
end
