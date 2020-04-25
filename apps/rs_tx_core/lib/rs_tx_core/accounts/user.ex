defmodule RsTxCore.Accounts.User do
  @moduledoc false

  use RsTxCore.Schema

  alias Bcrypt, as: Hasher
  alias Ecto.{Changeset, UUID}

  alias RsTxCore.Accounts.UserRole

  alias __MODULE__, as: Entity

  @type t :: __MODULE__

  @password_regex ~r/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*\W)/
  @email_regex ~r/^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i

  schema "users" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:confirmed?, :boolean, default: false, source: :is_confirmed)

    field(:password_reset_id, :binary_id)

    has_many(:user_roles, UserRole)
    has_many(:roles, through: [:user_roles, :role])

    timestamps(type: :utc_datetime_usec)
  end

  @spec register_changeset(t(), map) :: Changeset.t()
  def register_changeset(%Entity{} = entity, attrs) do
    fields = [:email, :password]

    entity
    |> Changeset.cast(attrs, fields)
    |> Changeset.validate_required(fields)
    |> validate_email()
    |> validate_password()
  end

  @spec confirm_changeset(t()) :: Changeset.t()
  def confirm_changeset(%Entity{} = entity) do
    entity
    |> Changeset.cast(%{}, [])
    |> Changeset.change(%{confirmed?: true})
  end

  @spec request_password_reset_changeset(t()) :: Changeset.t()
  def request_password_reset_changeset(%Entity{} = entity) do
    entity
    |> Changeset.cast(%{}, [])
    |> Changeset.change(%{password_reset_id: UUID.generate()})
  end

  @spec reset_password_changeset(t(), map) :: Changeset.t()
  def reset_password_changeset(%Entity{} = entity, attrs) do
    entity
    |> Changeset.cast(attrs, [:password])
    |> Changeset.validate_required([:password])
    |> Changeset.change(%{password_reset_id: nil})
    |> validate_password()
  end

  @spec validate_email(Changeset.t()) :: Changeset.t()
  def validate_email(changeset) do
    field = :email

    changeset
    |> Changeset.validate_length(field, max: 254)
    |> Changeset.validate_format(field, @email_regex)
    |> Changeset.unique_constraint(field)
  end

  @spec validate_password(Changeset.t()) :: Changeset.t()
  def validate_password(changeset) do
    field = :password

    changeset
    |> Changeset.update_change(field, &String.trim/1)
    |> Changeset.validate_length(field, min: 8, max: 40)
    |> Changeset.validate_format(field, @password_regex)
    |> case do
      %Changeset{valid?: true} = inner_changeset ->
        if password = Changeset.get_change(inner_changeset, field) do
          Changeset.change(inner_changeset, Hasher.add_hash(password))
        else
          changeset
        end

      inner_changeset ->
        inner_changeset
    end
  end
end
