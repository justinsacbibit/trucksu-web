defmodule Trucksu.Userpage.Manager do
  @userpage_bucket Application.get_env(:trucksu, :userpage_file_bucket)
  @cache_name :userpage_cache

  defp cache_key(user_id), do: "#{user_id}"
  defp object_key(user_id), do: "#{user_id}"

  def upload(user_id, userpage) do
    ExAws.S3.put_object!(@userpage_bucket, object_key(user_id), userpage)
    Cachex.del(@cache_name, cache_key(user_id))
  end

  def get(user_id) do
    {_status, userpage} = Cachex.get(@cache_name, cache_key(user_id), fallback: fn(_key) ->
      case ExAws.S3.get_object(@userpage_bucket, object_key(user_id)) do
        {:ok, %{body: userpage}} -> userpage
        _ -> nil
      end
    end)
    userpage
  end
end
