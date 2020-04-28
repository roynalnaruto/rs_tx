defmodule RsTxCore.Projects.CreateProjectSpecTest do
  @moduledoc false

  use ExSpec, async: false
  use PropCheck
  use RsTxCore.ContextCase, async: false
  use RsTxCore.FileCase

  alias Ecto.Changeset

  alias RsTxCore.Factory, as: CoreFactory
  alias RsTxCore.Scalar, as: CoreScalar

  alias RsTxCore.Projects, as: ProjectContext
  alias ProjectContext.Project

  alias RsTxCore.PropertyType

  alias __MODULE__, as: Self

  context "Projects.create_project/2" do
    def valid_attrs(),
      do: CoreFactory.build(:create_project)

    describe "should work" do
      setup do
        user = CoreFactory.insert(:confirmed_user)

        {:ok, user: user}
      end

      it "with valid attributes", %{user: %{id: user_id}} do
        attrs = valid_attrs()

        %{
          public_key: expected_public_key,
          metadata: %{
            url: expected_url,
            overview: expected_overview,
            description: expected_description
          }
        } = attrs

        assert {:ok,
                %Project{
                  user_id: ^user_id
                } = project} = ProjectContext.create_project(user_id, attrs)

        assert %{
          public_key: ^expected_public_key,
          metadata: %{
            url: ^expected_url,
            overview: ^expected_overview,
            description: ^expected_description
          }
        } = project
      end
    end

    describe "should fail" do
      setup do
        user = CoreFactory.insert(:confirmed_user)

        {:ok, %{user: user}}
      end
      it "with invalid user" do
        assert {:error, :user_not_found} =
          ProjectContext.create_project(CoreScalar.uuid(), valid_attrs())
      end

      it "with unconfirmed user" do
        user = CoreFactory.insert(:unconfirmed_user)

        assert {:error, :action_invalid, :user_unconfirmed} =
          ProjectContext.create_project(user.id, valid_attrs())
      end

      it "with required attributes missing", %{user: %{id: user_id}} do
        incomplete_attrs =
          valid_attrs()
          |> Map.delete(:public_key)

        assert {:error, %Changeset{valid?: false}} =
          ProjectContext.create_project(user_id, incomplete_attrs)
      end

      def invalid_url do
        valid_regex = ~r/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

        such_that(
          url <- PropertyType.string(10, 20),
          when: not String.match?(url, valid_regex)
        )
      end

      def invalid_public_key do
        valid_regex = ~r/^(0x)?[0-9a-fA-F]{66}$/i

        such_that(
          public_key <- PropertyType.string(68, 69),
          when: not String.match?(public_key, valid_regex)
        )
      end

      def invalid_overview do
        PropertyType.string(256, 300)
      end

      defmacro refute_property(field, gen) do
        quote do
          %{id: user_id} = CoreFactory.insert(:confirmed_user)

          forall value <- unquote(gen) do
            attrs = valid_attrs()

            attrs = case Map.has_key?(attrs, unquote(field)) do
              true -> Map.put(attrs, unquote(field), value)
              false -> Kernel.put_in(attrs, [:metadata, unquote(field)], value)
            end

            match?(
              {:error, %Changeset{errors: [{unquote(field), _}]}},
              attrs
              |> (&ProjectContext.create_project(user_id, &1)).()
            )
          end
        end
      end

      property "when url is invalid", [:quiet, numtests: 10] do
        refute_property(:url, Self.invalid_url())
      end

      property "when public key is invalid", [:quiet, numtests: 10] do
        refute_property(:public_key, Self.invalid_public_key())
      end

      property "when overview is invalid", [:quiet, numtests: 10] do
        refute_property(:overview, Self.invalid_overview())
      end
    end
  end
end
