defmodule RsTxCore.Factories.AccountsFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias RsTxCore.{Scalar}

      alias RsTxCore.Accounts, as: AccountContext
      alias AccountContext.User

      def register_user_factory do
        %{
          email: Scalar.email(),
          password: Scalar.password(),
        }
      end

      def register_account_factory do
        build(:register_user)
      end

      def reset_password_factory do
        %{password: Scalar.password()}
      end
    end
  end
end
