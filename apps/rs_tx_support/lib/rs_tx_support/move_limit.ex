defmodule RsTxSupport.MoveLimit do
  @moduledoc """
  This is `Honeydew.FailureMode.Move` but with a message throttling cap
  """

  alias Honeydew.{Job}
  alias Honeydew.FailureMode.{Abandon, Move}

  require Logger

  @behaviour Honeydew.FailureMode

  @impl true
  def validate_args!(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> validate_args!(__MODULE__)
  end

  def validate_args!(args, module \\ __MODULE__)

  def validate_args!(%{job_limit: limit}, module) when not is_integer(limit) or limit <= 0 do
    raise ArgumentError,
          "You provided a bad `:job_limit` argument (#{inspect(limit)}) to the #{module} failure mode, it's expecting a positive number."
  end

  def validate_args!(%{queue: {:global, queue}}, module)
      when not (is_atom(queue) or is_binary(queue)) do
    raise ArgumentError,
          "You provided a bad `:queue` argument (#{inspect(queue)}) to the #{module} failure mode, it's expecting an atom or string"
  end

  def validate_args!(%{queue: {:global, _queue}} = args, module),
    do: args |> Map.drop([:queue]) |> validate_args!(module)

  def validate_args!(%{queue: queue} = args, module),
    do: args |> Map.put(:queue, {:global, queue}) |> validate_args!(module)

  def validate_args!(%{finally: {module, args} = bad}, module)
      when not is_atom(module) or not is_list(args) do
    raise ArgumentError,
          "You provided a bad `:finally` argument (#{inspect(bad)}) to the #{module} failure mode, it's expecting `finally: {module, args}`"
  end

  def validate_args!(%{job_limit: _, finally: {m, a}}, _module),
    do: m.validate_args!(a)

  def validate_args!(%{job_limit: _}, _module), do: :ok

  def validate_args!(bad, module) do
    raise ArgumentError,
          "You provided bad arguments (#{inspect(bad)}) to the #{module} failure mode, at a minimum, it must be a list with a maximum number of retries specified, for example: `[queue: to_queue, job_limit: job_limit]`"
  end

  @impl true
  def handle_failure(%Job{} = job, reason, base_args) do
    args =
      base_args
      |> Enum.into(%{})
      |> (&Map.merge(%{finally: {Abandon, []}}, &1)).()

    %{queue: to_queue, job_limit: limit, finally: {finally_module, finally_args}} = args

    count =
      to_queue
      |> Honeydew.status()
      |> get_in([:queue, :count])

    if count < limit do
      Move.handle_failure(job, reason, queue: to_queue)
    else
      Logger.info("Job could not be moved because it exceeds job limit.")

      finally_module.handle_failure(job, reason, finally_args)
    end
  end
end
