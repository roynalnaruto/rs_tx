defmodule RsTxApiWeb.Resolvers.AccountResolver do
  @moduledoc false

  require Logger

  alias Ecto.Changeset

  alias RsTxCore.Accounts, as: AccountContext
  alias AccountContext.User

  alias RsTxApi.Guardian, as: ApiGuardian
  alias RsTxApi.Token

  def current_user(_parent, _args, %{context: %{current_user: current_user}}) do
    {:ok, current_user}
  end

  def register_user(_parent, args, _resolution) do
    case AccountContext.register_account(args) do
      {:ok, %User{id: id}} ->
        %{id: id, errors: nil}

      {:error, %Changeset{} = changeset} ->
        %{id: nil, errors: changeset}
    end
    |> (&{:ok, &1}).()
  end

  def sign_in(_parent, %{email: email, password: password}, _resolution) do
    case AccountContext.find_by_credentials(email, password) do
      {:ok, user} ->
        {:ok, token, claims} = ApiGuardian.encode_and_sign(user)

        %{
          authorization: %{
            jwt: token,
            exp: claims["exp"] |> Timex.from_unix()
          },
          errors: []
        }

      {:error, :user_unconfirmed} ->
        %{
          authorization: nil,
          errors: {:user_unconfirmed, "Please confirm email first"}
        }

      {:error, :user_not_registered} ->
        {:ok, _} = AccountContext.request_password_reset(email)

        %{
          authorization: nil,
          errors:
            {:user_not_registered,
             "You are required to reset your password on the first login. Please check #{email} to reset your password."}
        }

      {:error, :credentials_invalid} ->
        %{
          authorization: nil,
          errors: {:credentials_invalid, "Invalid username or password"}
        }
    end
    |> (&{:ok, &1}).()
  end

  def request_password_reset(_parent, %{email: email}, _resolution) do
    case AccountContext.request_password_reset(email) do
      {:ok, _reset_id} ->
        %{errors: []}

      {:error, :action_invalid, :user_unconfirmed} ->
        %{errors: {:user_not_found, "User not found"}}

      {:error, :user_not_found} ->
        %{errors: {:user_not_found, "User not found"}}
    end
    |> (&{:ok, &1}).()
  end

  def reset_password(_parent, args, _res) do
    token = Map.get(args, :token, "")

    with {:ok, reset_id} <-
           Token.verify(token, max_age: reset_password_duration()),
         {:ok, _user} <- AccountContext.reset_password(reset_id, args) do
      %{errors: []}
    else
      {:error, %Changeset{} = changeset} ->
        %{errors: changeset}

      {:error, :password_reset_not_found} ->
        %{errors: %{token: "is invalid/expired/used"}}

      {:error, err} when err in [:invalid, :expired] ->
        %{errors: %{token: "is invalid/expired/used"}}

      _ ->
        %{errors: {:action_invalid, "Invalid action"}}
    end
    |> (&{:ok, &1}).()
  end

  defp reset_password_duration() do
    token_config()[:reset_password_duration] || div(:timer.hours(6), :timer.seconds(1))
  end

  defp token_config() do
    Application.fetch_env!(:rs_tx_api, Token)
  end
end
