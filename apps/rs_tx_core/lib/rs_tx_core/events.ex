defmodule RsTxCore.EventMacros do
  @moduledoc false

  use EventBus.EventSource

  defmacro defevent({_, _, _} = fundef, do: body) do
    decorated =
      quote do
        {topic, data} = unquote(body)

        EventSource.notify %{topic: topic} do
          data
        end

        :ok
      end

    quote do
      def(unquote(fundef), unquote(do: decorated))
    end
  end
end

defmodule RsTxCore.Events do
  @moduledoc false

  use EventBus.EventSource

  require RsTxCore.EventMacros
  import RsTxCore.EventMacros

  alias RsTxCore.Accounts, as: AccountContext
  alias AccountContext.User

  defevent account_registered(%User{id: id}) do
    {:account_registered, %{user_id: id}}
  end

  defevent password_reset_requested(%User{id: id}, password_reset_id) do
    {:password_reset_requested, %{user_id: id, password_reset_id: password_reset_id}}
  end

  defevent password_changed(%User{id: id}) do
    {:password_changed, %{user_id: id}}
  end
end
