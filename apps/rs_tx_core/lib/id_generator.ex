defmodule IdGenerator do
  @moduledoc false

  alias Ecto.UUID

  defdelegate unique_id(), to: UUID, as: :generate
end
