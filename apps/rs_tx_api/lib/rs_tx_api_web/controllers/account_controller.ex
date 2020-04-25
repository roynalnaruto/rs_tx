defmodule RsTxApiWeb.AccountController do
  use RsTxApiWeb, :controller

  alias RsTxCore.Accounts, as: AccountContext

  alias RsTxApi.Token

  def confirmation(conn, params) do
    token = Map.get(params, "token", "")

    error =
      with {:ok, user_id} <- Token.verify(token, max_age: :infinity),
           {:ok, _confirmed_user} <- AccountContext.confirm_user(user_id) do
        ""
      else
        _ -> "token_invalid"
      end

    redirect(conn, external: "#{confirmation_uri()}?error=#{error}")
  end

  def password_reset(conn, params) do
    token = Map.get(params, "token", "")

    {checked_token, error} =
      with {:ok, reset_id} <- Token.verify(token, max_age: reset_password_duration()),
           {:ok, _user} <-
             if(user = AccountContext.get_by_password_reset_id(reset_id),
               do: {:ok, user},
               else: {:error, :user_not_found}
             ) do
        {token, ""}
      else
        _ -> {"", "token_invalid"}
      end

    redirect(conn,
      external: "#{reset_password_uri()}?reset_password_token=#{checked_token}&error=#{error}"
    )
  end

  defp confirmation_uri() do
    config()[:confirmation_uri] || "https://localhost:5000/#/portal/register/confirmation"
  end

  defp reset_password_uri() do
    config()[:reset_password_uri] || "https://localhost:5000/#/portal/forgot-password/reset-form"
  end

  defp reset_password_duration() do
    token_config()[:reset_password_duration] || div(:timer.hours(6), :timer.seconds(1))
  end

  defp config() do
    Application.fetch_env!(:rs_tx_api, __MODULE__)
  end

  defp token_config() do
    Application.fetch_env!(:rs_tx_api, Token)
  end
end
