defmodule RsTxApiWeb.Router do
  use RsTxApiWeb, :router

  def add_rate_limit_headers(conn, %Absinthe.Blueprint{} = blueprint) do
    case blueprint.execution.context do
      %{remaining_limit: remaining_limit, limit: limit} ->
        conn
        |> Plug.Conn.put_resp_header("x-rate-limit-limit", to_string(remaining_limit))
        |> Plug.Conn.put_resp_header("x-rate-limit-remaining", to_string(limit))

      _ ->
        conn
    end
  end

  def add_rate_limit_headers(conn, _),
    do: conn

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug RsTxApiWeb.Context
  end

  scope "/" do
    pipe_through :api

    scope "/" do
      pipe_through RsTxApiWeb.GuardianPipeline
      pipe_through :graphql

      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: RsTxApiWeb.Schema,
        socket: RsTxApiWeb.UserSocket,
        interface: :advanced,
        context: %{pubsub: RsTxApiWeb.Endpoint},
        max_complexity: 70,
        before_send: {__MODULE__, :add_rate_limit_headers}

      forward "/graphql", Absinthe.Plug,
        schema: RsTxApiWeb.Schema,
        analyze_complexity: true,
        max_complexity: 70,
        before_send: {__MODULE__, :add_rate_limit_headers}
    end

    if Mix.env() == :dev do
      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    end

    forward(
      "/health",
      PlugCheckup,
      PlugCheckup.Options.new(
        json_encoder: Jason,
        checks: [
          %PlugCheckup.Check{
            name: "DB",
            module: RsTxApiWeb.HealthChecks,
            function: :check_db
          }
        ]
      )
    )

    scope "/accounts", RsTxApiWeb do
      get "/confirmation", AccountController, :confirmation
      get "/passwordReset", AccountController, :password_reset
    end
  end
end
