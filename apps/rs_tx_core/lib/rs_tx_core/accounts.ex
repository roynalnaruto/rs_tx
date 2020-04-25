defmodule RsTxCore.Accounts do
  @moduledoc false

  alias Bcrypt, as: Hasher
  alias Ecto.Changeset

  alias RsTxCore.{Events, Repo}

  alias RsTxCore.Accounts, as: AccountContext
  alias AccountContext.{User, AccountPolicy}

  @type id :: UUID.t()

  @spec get_by_id(id) :: User.t() | nil
  def get_by_id(id) do
    Repo.get_by(User, id: id)
  end

  @spec fetch_by_id(id) :: {:ok, User.t()} | {:error, :user_not_found}
  def fetch_by_id(id) do
    if user = get_by_id(id) do
      {:ok, user}
    else
      {:error, :user_not_found}
    end
  end

  @spec get_by_email(charlist()) :: User.t() | nil
  def get_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @spec get_by_password_reset_id(charlist()) :: User.t() | nil
  def get_by_password_reset_id(password_reset_id) do
    Repo.get_by(User, password_reset_id: password_reset_id)
  end

  @spec register_user(map()) ::
          {:ok, User.t()}
          | {:error, Changeset.t()}
  def register_user(attrs) do
    %User{confirmed?: false}
    |> User.register_changeset(attrs)
    |> Repo.insert()
  end

  @spec register_account(map()) ::
          {:ok, User.t()}
          | {:error, Changeset.t()}
  def register_account(attrs) do
    Repo.transaction(fn ->
      with {:ok, user} <- AccountContext.register_user(attrs) do
        user
      else
        {:error, :action_invalid, _} -> raise "Should not happen"
        {:error, %Changeset{} = changeset} -> Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, user} ->
        :ok = Events.account_registered(user)

        {:ok, user}

      error ->
        error
    end
  end

  @spec confirm_user(id) ::
          {:ok, User.t()}
          | {:error, :user_not_found}
          | {:error, :action_invalid, :user_already_confirmed}
  def confirm_user(id) do
    with {:ok, user} <- fetch_by_id(id),
         :ok <- check_policy(:confirm_account, user, nil) do
      user
      |> User.confirm_changeset()
      |> Repo.update()
    else
      error -> error
    end
  end

  @spec request_password_reset(id()) ::
          {:ok, id()}
          | {:error, :user_not_found}
          | {:error, :action_invalid, :user_unconfirmed}
  def request_password_reset(email) do
    with {:ok, user} <- fetch_email(email),
         :ok <- check_policy(:request_password_reset, user, nil),
         {:ok, updated_user} <-
           user
           |> User.request_password_reset_changeset()
           |> Repo.update() do
      %User{password_reset_id: password_reset_id} = updated_user

      :ok = Events.password_reset_requested(updated_user, password_reset_id)

      {:ok, password_reset_id}
    else
      error -> error
    end
  end

  @spec reset_password(id(), map()) ::
          {:ok, id()}
          | {:error, :password_reset_not_found}
          | {:error, :action_invalid, :user_unconfirmed}
          | {:error, :action_invalid, :password_reset_invalid}
          | {:error, Changeset.t()}
  def reset_password(reset_id, attrs) do
    with {:ok, user} <- fetch_password_reset(reset_id),
         :ok <- check_policy(:reset_password, user, reset_id),
         {:ok, updated_user} <-
           user
           |> User.reset_password_changeset(attrs)
           |> Repo.update() do
      :ok = Events.password_changed(updated_user)

      {:ok, updated_user}
    else
      error -> error
    end
  end

  @spec find_by_credentials(charlist(), charlist()) ::
          {:ok, User.t()}
          | {:error, :credentials_invalid}
          | {:error, :user_unconfirmed}
  def find_by_credentials(email, password) do
    if user = get_by_email(email) do
      cond do
        not user.confirmed? ->
          {:error, :user_unconfirmed}

        true ->
          case Hasher.check_pass(user, password) do
            {:error, _} -> {:error, :credentials_invalid}
            {:ok, _} -> {:ok, user}
          end
      end
    else
      {:error, :credentials_invalid}
    end
  end

  defp fetch_email(email) do
    if user = get_by_email(email) do
      {:ok, user}
    else
      {:error, :user_not_found}
    end
  end

  defp fetch_password_reset(nil),
    do: {:error, :user_not_found}

  defp fetch_password_reset(reset_id) do
    if user = Repo.get_by(User, password_reset_id: reset_id) do
      {:ok, user}
    else
      {:error, :password_reset_not_found}
    end
  end

  defp check_policy(action, user, attrs) do
    case Bodyguard.permit(AccountPolicy, action, user, attrs) do
      :ok -> :ok
      {:error, reason} -> {:error, :action_invalid, reason}
    end
  end
end
