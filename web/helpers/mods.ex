defmodule Trucksu.Helpers.Mods do
  use Bitwise

  def is_mod_enabled(enabled_mods, mod) do
    band(enabled_mods, mod) != 0
  end
end

