defmodule RsTxCore.Accounts.AccountPolicy do
  @moduledoc false

  @behaviour Bodyguard.Policy

  alias RsTxCore.Support.CommonPolicy

  @impl true
  def authorize(:confirm_account, user, _attrs) do
    if user.confirmed? do
      {:error, :user_already_confirmed}
    else
      :ok
    end
  end

  @impl true
  def authorize(:request_password_reset, user, _attrs) do
    CommonPolicy.user_confirmed?(user)
  end

  @impl true
  def authorize(:reset_password, user, password_reset_id) do
    cond do
      not user.confirmed? ->
        {:error, :user_unconfirmed}

      is_nil(password_reset_id) or user.password_reset_id != password_reset_id ->
        {:error, :password_reset_invalid}

      true ->
        :ok
    end
  end

  @impl true
  def authorize(_, _, _),
    do: false
end
