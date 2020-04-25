defmodule RsTxApi.Application do
  @moduledoc false

  use Application

  alias RsTxApi, as: Api
  alias RsTxApiWeb, as: Web

  defmodule EventSubscribers do
    @moduledoc false

    use Supervisor

    alias Guardian

    alias RsTxApi.{EventSubscriber, MailerSubscriber}
    alias RsTxApiWeb.SubscriptionSubscriber

    def start_link(opts) do
      Supervisor.start_link(__MODULE__, opts)
    end

    @impl true
    def init(_opts) do
      children = [
        {Guardian.DB.Token.SweeperServer, []},
        {EventSubscriber, []},
        {MailerSubscriber, []},
        {SubscriptionSubscriber, []}
      ]

      Supervisor.init(children,
        strategy: :one_for_one,
        restart: :transient,
        name: RsTxApi.EventSubscribers.Supervisor
      )
    end
  end

  def start(_type, _args) do
    children = [
      Api.Cache,
      Web.Endpoint,
      EventSubscribers,
      {Absinthe.Subscription, [Web.Endpoint]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: RsTxApi.Supervisor)
  end

  def config_change(changed, _new, removed) do
    RsTxApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
