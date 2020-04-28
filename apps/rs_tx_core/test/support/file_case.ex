defmodule RsTxCore.FileCase do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      setup_all do
        Temp.track!()

        if not is_nil(System.get_env("TMP")) do
          System.delete_env("TMP")
        end

        tmp_dir = Temp.mkdir!("rs_tx_core_tmp")
        File.chmod!(tmp_dir, 0o777)

        System.put_env("TMP", tmp_dir)

        on_exit(fn ->
          File.rm_rf(tmp_dir)
        end)

        :ok
      end
    end
  end
end
