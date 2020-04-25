defmodule RsTxApi.MailerSubscriber do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger

  alias Bamboo.Email
  alias Honeydew

  alias RsTxCore.Accounts, as: AccountContext

  alias RsTxSupport.{DiscMnesiaQueue, MoveLimit}

  alias RsTxApi.{Emails, Mailer}

  @queue_name :send_mail
  @resend_queue_name :resend_mail

  @events [
    :account_registered,
    :password_reset_requested,
    :password_changed
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  defmodule SendMailWorker do
    @moduledoc false

    @behaviour Honeydew.Worker

    require Logger

    alias RsTxApi.Mailer

    def init(_args) do
      {:ok, nil}
    end

    def send_mail(%Email{to: to, subject: subject} = email, _state) do
      Logger.info("Sending #{subject} email to #{to}")

      email
      |> Mailer.deliver_now()
      |> case do
        %Email{} ->
          :ok

        _ ->
          raise RuntimeError, "Could not send email"
      end
    end
  end

  defmodule ResendMailWorker do
    @moduledoc false

    @behaviour Honeydew.Worker

    require Logger

    alias Bamboo.Email
    alias Honeydew

    def init([to_queue, resend_delay]) do
      {:ok, {to_queue, resend_delay}}
    end

    def send_mail(%Email{to: to, subject: subject} = mail, {to_queue, resend_delay}) do
      Logger.info("Requeuing #{to} #{subject} email")
      Honeydew.async({:send_mail, [mail]}, to_queue, delay_secs: resend_delay)

      :ok
    end
  end

  defp started?(:ok), do: :ok
  defp started?({:error, {:already_started, _}}), do: :ok

  @impl true
  def init(_opts) do
    :ok = EventBus.subscribe({__MODULE__, @events})

    nodes = [node()]

    :ok =
      Honeydew.start_queue(
        @queue_name,
        queue: {DiscMnesiaQueue, disc_only_copies: nodes},
        failure_mode: {
          Honeydew.FailureMode.ExponentialRetry,
          times: 3,
          base: 5,
          finally:
            {MoveLimit,
             queue: @resend_queue_name,
             job_limit: resend_limit(),
             finally: {Honeydew.FailureMode.Abandon, []}}
        }
      )
      |> started?()

    :ok =
      Honeydew.start_queue(
        @resend_queue_name,
        queue: {DiscMnesiaQueue, disc_only_copies: nodes},
        failure_mode: {Honeydew.FailureMode.Abandon, []}
      )
      |> started?()

    :ok = Honeydew.start_workers(@queue_name, {SendMailWorker, []}, num: 1) |> started?()

    :ok =
      Honeydew.start_workers(
        @resend_queue_name,
        {ResendMailWorker, [@queue_name, resend_delay()]},
        num: 1
      )
      |> started?()

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

  defp handle_event(:account_registered, %{user_id: user_id}) do
    if user = AccountContext.get_by_id(user_id) do
      Logger.info("Sending #{user_id} user confirmation email.")

      user
      |> Emails.confirmation_email()
      |> send_mail()

      :ok
    else
      :skip
    end
  end

  defp handle_event(:password_reset_requested, %{user_id: user_id, password_reset_id: reset_id}) do
    if user = AccountContext.get_by_id(user_id) do
      Logger.info("Sending #{user_id} password reset email.")

      user
      |> Emails.password_reset_email(reset_id)
      |> send_mail()

      :ok
    else
      :skip
    end
  end

  defp handle_event(:password_changed, %{user_id: user_id}) do
    if user = AccountContext.get_by_id(user_id) do
      Logger.info("Sending #{user_id} password changed email.")

      user
      |> Emails.password_changed_email()
      |> send_mail()

      :ok
    else
      :skip
    end
  end

  defp handle_event(action, _) do
    Logger.debug("#{action} was not handled")

    :skip
  end

  defp send_mail(mail) do
    Honeydew.async({:send_mail, [mail]}, @queue_name)
  end

  defp resend_delay() do
    milliseconds = config()[:resend_delay] || :timer.minutes(5)

    div(milliseconds, :timer.seconds(1))
  end

  defp resend_limit() do
    config()[:resend_limit] || 100
  end

  defp config() do
    Application.get_env(:rs_tx_api, __MODULE__)
  end

  if Mix.env() == :test do
    def events() do
      @events
    end
  end
end
