Application.ensure_all_started(:ex_machina)
Application.ensure_all_started(:faker)
Application.ensure_all_started(:mogrify)

Application.ensure_all_started(:rs_tx_core)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(RsTxCore.Repo, :manual)
