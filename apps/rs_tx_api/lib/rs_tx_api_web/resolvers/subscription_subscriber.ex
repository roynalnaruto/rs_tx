defmodule RsTxApiWeb.SubscriptionSubscriber do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger

  @events []

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
