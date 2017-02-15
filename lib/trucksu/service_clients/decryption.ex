defmodule Trucksu.ServiceClients.Decryption do
  @moduledoc """
  Client module for making requests to the Decryption service.

  Used to decrypt score submission data.
  """

  @doc """
  Decrypts the given ciphertext.

  Arguments:
  * `ciphertext` - The ciphertext to be decrypted
  * `key` - The encryption key
  * `iv` - The initialization vector
  """
  def decrypt(ciphertext, key, iv) do
    decryption_url = get_decryption_url()
    if decryption_url do
      decryption_cookie = get_decryption_cookie()
      request_body = {:form, [
        {"c", ciphertext},
        {"iv", iv},
        {"k", key},
        {"cookie", decryption_cookie},
      ]}
      %HTTPoison.Response{body: plaintext} = HTTPoison.post!(decryption_url, request_body)
      plaintext
    else
      {plaintext, 0} = System.cmd("php", ["score.php", key, ciphertext, iv])
      plaintext
    end
  end

  ## Configuration

  defp get_decryption_url() do
    Application.get_env(:trucksu, :decryption_url)
  end

  defp get_decryption_cookie() do
    Application.get_env(:trucksu, :decryption_cookie)
  end
end
