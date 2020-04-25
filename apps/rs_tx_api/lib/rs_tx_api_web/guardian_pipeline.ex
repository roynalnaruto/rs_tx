defmodule RsTxApiWeb.GuardianPipeline do
  @moduledoc false

  use Guardian.Plug.Pipeline, otp_app: :rs_tx_api

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
