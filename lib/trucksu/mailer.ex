defmodule Trucksu.Mailer do
  @website_url Application.get_env(:trucksu, :website_url)
  @config domain: Application.get_env(:trucksu, :mailgun_domain),
          key: Application.get_env(:trucksu, :mailgun_key)
  use Mailgun.Client, @config

  @from "noreply@trucksu.com"

  defp verification_html(user, token), do: """
  Hi,
  <br><br>
  This email was recently used to create a Trucksu account with the username "#{user.username}". If this is you, please <a href="#{verify_url(token)}">click here</a>, or paste the following link into your browser:
  <br><br>
  #{verify_url(token)}
  <br><br>
  If you did not register this account, please ignore this email.
  <br><br>
  Trucksu Team
  """

  defp verify_url(token) do
    "#{@website_url}/verify-email?t=#{token}"
  end

  def send_verification_email(user, token) do
    send_email to: user.email,
               from: @from,
               subject: "Trucksu Account Verification",
               html: verification_html(user, token)
  end
end

