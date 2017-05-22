defmodule Trucksu.Osu do
  use HTTPoison.Base
  require Logger

  defp process_url(url) do
    "https://osu.ppy.sh/api" <> url
  end

  defp process_request_body(body) do
    Poison.encode!(body)
  end

  defp process_response_body(body) do
    Poison.decode!(body)
  end

  @doc ~S"""
  Issues an HTTP request to the osu! API to the /get_user endpoint.

  Args:
    * `user` - The username or user id of the user.
    * `params` - Keyword list of optional parameters.

  Params:
    * `:m` - mode (0 = osu!, 1 = Taiko, 2 = CtB, 3 = osu!mania). Default is 0.
  """
  def get_user!(user, params \\ []) do
    params = Keyword.put(params, :u, user)

    _get!("/get_user", params)
  end

  @doc ~S"""
  Issues an HTTP request to the osu! API to the /get_user_best endpoint.

  Args:
    * `user` - The username or user id of the user.
    * `params` - Keyword list of optional parameters.

  Params:
    * `:m` - mode (0 = osu!, 1 = Taiko, 2 = CtB, 3 = osu!mania). Default is 0.
  """
  def get_user_best!(user, params \\ []) do
    params = params
    |> Keyword.put(:u, user)
    |> Keyword.put(:limit, 100)

    _get!("/get_user_best", params)
  end

  @doc ~S"""
  Issues an HTTP request to the osu! API to the /get_beatmaps endpoint.

  Args:
    * `params` - Keyword list of optional parameters.

  Params:
    * `:b` - The beatmap id of a single beatmap.
  """
  def get_beatmaps!(params \\ []) do
    _get!("/get_beatmaps", params)
  end
  def get_beatmaps(params \\ []) do
    _get("/get_beatmaps", params)
  end

  defp _get(path, params) do
    inner_get(path, params, false)
  end

  defp _get!(path, params) do
    inner_get(path, params, true)
  end

  defp inner_get(path, params, bang) do
    params = Keyword.put(params, :k, Application.get_env(:trucksu, :osu_api_key))
    one_minute = 60000
    opts = [params: params, timeout: one_minute, recv_timeout: one_minute]

    Logger.warn "Executing osu! API call: path=#{path} params=#{inspect params} bang=#{bang}"

    if bang do
      get!(path, [], opts)
    else
      get(path, [], opts)
    end
  end
end
