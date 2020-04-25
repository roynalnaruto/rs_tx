defmodule RsTxApi.Guardian do
  @moduledoc false

  use Guardian, otp_app: :rs_tx_api

  alias Guardian

  alias RsTxCore.Accounts, as: AccountContext
  alias AccountContext.User

  def subject_for_token(%User{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _),
    do: {:error, :reason_for_error}

  def resource_from_claims(claims) do
    id = claims["sub"]

    if user = AccountContext.get_by_id(id),
      do: {:ok, user},
      else: {:error, :claim_invalid}
  end

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end
