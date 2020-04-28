defmodule RsTxCore.ContextCase do
  @moduledoc false

  use PropCheck

  defmacro __using__(_opts) do
    quote do
      import RsTxCore.ContextCase

      setup do
        :dets.start()
        :mnesia.start()

        Application.ensure_all_started(:rs_tx_core)

        :ok
      end

      setup tags do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(RsTxCore.Repo)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(RsTxCore.Repo, {:shared, self()})
        end

        :ok
      end

      setup do
        if is_nil(Process.whereis(__MODULE__)) do
          Process.register(self(), __MODULE__)
        end

        :ok
      end

      setup do
        EventBus.subscribe({__MODULE__, [".*"]})

        on_exit(fn ->
          EventBus.unsubscribe(__MODULE__)
        end)

        :ok
      end

      def process({topic, _id} = event_shadow) do
        event = EventBus.fetch_event(event_shadow)

        send(__MODULE__, {topic, event.data})

        EventBus.mark_as_completed({__MODULE__, event_shadow})
      end

      def enum_keys(enum) do
        enum.__enum_map__()
        |> Enum.map(&elem(&1, 0))
      end
    end
  end
end
