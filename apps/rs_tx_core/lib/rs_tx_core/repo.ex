defmodule RsTxCore.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :rs_tx_core,
    adapter: Ecto.Adapters.Postgres
end
