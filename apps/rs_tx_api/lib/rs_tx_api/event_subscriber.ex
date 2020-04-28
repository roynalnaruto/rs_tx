defmodule RsTxApi.EventSubscriber do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger

  import Ecto.Query
  alias Ecto

  alias RsTxCore.Repo

  alias RsTxCore.Accounts, as: AccountContext

  alias RsTxApi.{Guardian}

  @events [
    :password_changed
  ]

  defmodule Token do
    @moduledoc false

    use Ecto.Schema

    schema "guardian_tokens" do
      field(:typ, :string)
      field(:aud, :string)
      field(:iss, :string)
      field(:sub, :string)
      field(:exp, :integer)
      field(:jwt, :string)
      field(:claims, :map)

      timestamps()
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :ok = EventBus.subscribe({__MODULE__, @events})

    {:ok, nil}
  end

  def process(event_shadow) do
    GenServer.cast(__MODULE__, event_shadow)

    :ok
  end

  @impl true
  def handle_cast({action, _id} = event_shadow, state) do
    if event = EventBus.fetch_event(event_shadow) do
      case handle_event(action, event.data) do
        :ok ->
          EventBus.mark_as_completed({__MODULE__, event_shadow})

        :skip ->
          EventBus.mark_as_skipped({__MODULE__, event_shadow})
      end
    else
      EventBus.mark_as_skipped({__MODULE__, event_shadow})
    end

    {:noreply, state}
  end

  defp handle_event(:password_changed, %{user_id: user_id}) do
    with {:ok, user} <- AccountContext.fetch_by_id(user_id),
         {:ok, subject} <- Guardian.subject_for_token(user, nil) do
      query =
        from(t in Token,
          where: t.sub == ^subject
        )

      {_, _} = Repo.delete_all(query)

      Logger.info("User #{user_id} sessions are removed")

      :ok
    else
      _ -> :skip
    end
  end

  defp handle_event(action, _) do
    Logger.debug("#{action} was not handled")

    :skip
  end

  if Mix.env() == :test do
    def events() do
      @events
    end
  end
end
