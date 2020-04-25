defmodule RsTxApiWeb.Schema.AccountTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias RsTxApiWeb.Resolvers
  alias RsTxApiWeb.Schema.Middlewares

  object :user do
    description("Platform users to buy DGX")

    field :id, non_null(:id), description: "User ID"
    field :email, non_null(:string), description: "User email"
  end

  object :authorization do
    description("""
    Authorization via Bearer Token.

    Set all the fields in this object as HTTP headers when making request to use this.
    """)

    field :jwt, non_null(:string), description: "JWT token"
    field :exp, non_null(:timestamp), description: "JWT expiration in seconds"
  end

  object :account_queries do
    field :current_user, non_null(:user) do
      description("""
      Get the current user's information.

      Authorization Required
      """)

      complexity(3)

      middleware(Middlewares.Authenticated)
      resolve(&Resolvers.AccountResolver.current_user/3)
    end
  end

  object :account_mutations do
    mutation do
      payload field :register_user do
        description("""
        Register user.

        Once registered, an email is sent to the user's address for the confirmation link.
        """)

        input do
          field :email, non_null(:string),
            description: """
            User's email.

            Validations:
            - Maximum of 254 characters
            - Must be of this format: `<name_part>@<domain_part>`
            """

          field :password, non_null(:string),
            description: """
            User's password.

            Validations:
            - Minimum of 6 characters
            - Maximum of 128 characters
            """
        end

        output do
          field :id, :id, description: "ID of the new unconfirmed user"

          field :errors, list_of(:field_error) do
            description("""
            Mutation errors.

            Operation Errors:
            - Email is already used
            """)

            middleware(Middlewares.TranslateErrors)
          end
        end

        resolve(&Resolvers.AccountResolver.register_user/3)
      end

      payload field :sign_in do
        description("""
        Sign in via email and password.
        """)

        input do
          field :email, non_null(:string),
            description: """
            Email of the user

            Validations:
            - No validation
            """

          field :password, non_null(:string),
            description: """
            Password of the user

            Validations:
            - No validation
            """
        end

        output do
          field :authorization, :authorization

          field :errors, list_of(:field_error) do
            description("""
            Mutation errors

            Operation Errors:
            - User is not yet confirmed
            - Invalid email/password
            """)

            middleware(Middlewares.TranslateErrors)
          end
        end

        resolve(&Resolvers.AccountResolver.sign_in/3)
      end

      payload field :request_password_reset do
        description("""
        Request a password resetet of a confirmed user via email.

        Once requested, an email is sent to the address for the reset
        password link. If the email is unconfirmed, it is considered not
        found.
        """)

        input do
          field :email, non_null(:string),
            description: """
            Email of the user

            Validations:
            - No validation
            """
        end

        output do
          field :errors, non_null(list_of(non_null(:field_error))) do
            description("""
            Mutation errors.

            Operation Errors:
            - User not found
            """)

            middleware(Middlewares.TranslateErrors)
          end
        end

        resolve(&Resolvers.AccountResolver.request_password_reset/3)
      end

      payload field :reset_password do
        description("""
        Given a password reset token, change the user password to a new one.

        Once the token is used, it cannot be used again.
        """)

        input do
          field :token, non_null(:string),
            description: """
            User's password reset token.

            Validations:
            - Token invalid/expired/used
            - Must be used within 6 hours
            """

          field :password, non_null(:string),
            description: """
            User's password.

            Validations:
            - Minimum of 6 characters
            - Maximum of 128 characters
            """
        end

        output do
          field :errors, non_null(list_of(non_null(:field_error))) do
            description("""
            Mutation errors.

            Operation Errors: None
            """)

            middleware(Middlewares.TranslateErrors)
          end
        end

        resolve(&Resolvers.AccountResolver.reset_password/3)
      end
    end
  end
end
