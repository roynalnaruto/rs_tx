defmodule RsTxApi.Emails do
  @moduledoc false

  use Bamboo.Phoenix, view: RsTxApiWeb.EmailView

  import Bamboo.Email
  import Bamboo.Phoenix

  alias RsTxCore.Accounts, as: AccountContext
  alias AccountContext.User

  alias RsTxApi.Token
  alias RsTxApiWeb.{Endpoint, Router}

  def confirmation_email(%User{id: id, email: email, updated_at: updated_at}) do
    token = Token.sign(id, signed_at: DateTime.to_unix(updated_at))

    base_email()
    |> to(email)
    |> subject("Confirmation Instructions")
    |> assign(:link, Router.Helpers.account_url(Endpoint, :confirmation, token: token))
    |> render("user_confirmation.html")
  end

  def password_reset_email(
        %User{id: _id, email: email, updated_at: updated_at},
        password_reset_id
      ) do
    token = Token.sign(password_reset_id, signed_at: DateTime.to_unix(updated_at))

    base_email()
    |> to(email)
    |> subject("Reset Password Instructions")
    |> assign(:link, Router.Helpers.account_url(Endpoint, :password_reset, token: token))
    |> render("password_reset.html")
  end

  def password_changed_email(%User{id: _id, email: email}) do
    base_email()
    |> to(email)
    |> subject("Password Changed")
    |> render("password_change.html")
  end

  defp base_email do
    new_email()
    |> from(email_from())
    |> put_html_layout({RsTxApiWeb.LayoutView, "email.html"})
  end

  defp email_from() do
    config()[:from] || "noreply@rstx.io"
  end

  defp config() do
    Application.get_env(:rs_tx_api, __MODULE__)
  end
end
