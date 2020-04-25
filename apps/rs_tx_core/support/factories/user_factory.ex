defmodule RsTxCore.Factories.UserFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Bcrypt, as: Hasher

      alias RsTxCore.Scalar

      alias RsTxCore.Accounts, as: AccountContext
      alias AccountContext.User

      def user_factory(attrs) do
        user_fields =
          User.__struct__()
          |> Map.keys()
          |> List.delete(:__meta__)
          |> List.delete(:__struct__)

        {user_attrs, _extra_attrs} = Map.split(attrs, user_fields)

        password = Map.get_lazy(user_attrs, :password, &Scalar.password/0)

        id = Scalar.uuid()

        %User{
          id: id,
          email: Scalar.email(),
          confirmed?: Scalar.boolean(),
        }
        |> Map.merge(Hasher.add_hash(password))
        |> Map.put(:password, password)
        |> merge_attributes(user_attrs)
      end

      def unconfirmed_user_factory(base_attrs) do
        {unconfirmed, attrs} = Map.pop(base_attrs, :confirmed?, false)

        build(:user, attrs)
        |> merge_attributes(%{confirmed?: unconfirmed})
      end

      def confirmed_user_factory(base_attrs) do
        {confirmed, attrs} = Map.pop(base_attrs, :confirmed?, true)

        build(:user, attrs)
        |> merge_attributes(%{confirmed?: confirmed})
      end

      def plain_user_factory(attrs) do
        build(:confirmed_user, attrs)
        |> merge_attributes(address_change_request: nil)
      end

      def password_reset_user_factory(base_attrs) do
        {reset_id, attrs} = Map.pop_lazy(base_attrs, :password_reset_id, &Scalar.uuid/0)

        build(:confirmed_user, attrs)
        |> merge_attributes(%{password_reset_id: reset_id})
      end
    end
  end
end
