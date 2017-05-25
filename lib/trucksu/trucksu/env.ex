defmodule Trucksu.Env do
  @moduledoc """
  Provides access to environment variables without having to call
  `Application.get_env/2`.
  """

  defp get_env(key), do: Application.get_env(:trucksu, key)

  def avatar_file_bucket(), do: get_env(:avatar_file_bucket)
  def bancho_url(), do: get_env(:bancho_url)
  def bot_url(), do: get_env(:bot_url)
  def replay_file_bucket(), do: get_env(:replay_file_bucket)
  def server_cookie(), do: get_env(:server_cookie)
end