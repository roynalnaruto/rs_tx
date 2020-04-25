defmodule RsTxSupport.MoveLimitTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  alias Honeydew
  alias Honeydew.FailureMode.Move

  alias RsTxSupport.MoveLimit

  alias RsTxSupport.Stateless

  @job_limit 3

  setup do
    Application.ensure_all_started(:honeydew)

    on_exit(fn ->
      Application.stop(:honeydew)
    end)

    :ok
  end

  setup do
    queue = :erlang.unique_integer()
    failure_queue = "#{queue}_failed"
    junk_queue = "#{queue}_junk"

    :ok =
      Honeydew.start_queue(queue,
        failure_mode:
          {MoveLimit,
           queue: failure_queue, job_limit: @job_limit, finally: {Move, queue: junk_queue}}
      )

    :ok = Honeydew.start_queue(failure_queue)
    :ok = Honeydew.start_queue(junk_queue)
    :ok = Honeydew.start_workers(queue, Stateless)

    [queue: queue, failure_queue: failure_queue, junk_queue: junk_queue]
  end

  test "validate_args!/1" do
    import MoveLimit, only: [validate_args!: 1]

    assert :ok = validate_args!(queue: :abc, job_limit: 3)
    assert :ok = validate_args!(queue: {:global, :abc}, job_limit: 3)

    assert_raise ArgumentError, fn ->
      validate_args!(:abc)
    end

    assert_raise ArgumentError, fn ->
      validate_args!(job_limit: -3)
    end
  end

  test "should move the job on the new queue", %{queue: queue, failure_queue: failure_queue} do
    {:crash, [self()]} |> Honeydew.async(queue)
    assert_receive :job_ran

    wait_for_queue(queue)

    assert Honeydew.status(queue) |> get_in([:queue, :count]) == 0
    refute_receive :job_ran

    assert failure_queue |> Honeydew.status() |> get_in([:queue, :count]) == 1
  end

  test "should move the job on the junk queue after job limit", %{
    queue: queue,
    failure_queue: failure_queue,
    junk_queue: junk_queue
  } do
    this = self()

    1..@job_limit
    |> Enum.each(fn _ ->
      {:crash, [this]} |> Honeydew.async(queue)
    end)

    assert_receive :job_ran

    wait_for_queue(queue)

    assert Honeydew.status(queue) |> get_in([:queue, :count]) == 0

    {:crash, [this]} |> Honeydew.async(queue)

    wait_for_queue(queue)

    assert failure_queue |> Honeydew.status() |> get_in([:queue, :count]) == @job_limit
    assert junk_queue |> Honeydew.status() |> get_in([:queue, :count]) == 1
  end

  test "should inform the awaiting process of the exception", %{
    queue: queue,
    failure_queue: failure_queue
  } do
    job =
      {:crash, [self()]}
      |> Honeydew.async(queue, reply: true)

    assert {:moved, {%RuntimeError{message: "ignore this crash"}, _stacktrace}} =
             Honeydew.yield(job)

    :ok = Honeydew.start_workers(failure_queue, Stateless)

    # job ran in the failure queue
    assert {:error, {%RuntimeError{message: "ignore this crash"}, _stacktrace}} =
             Honeydew.yield(job)
  end

  test "should inform the awaiting process of the uncaught throw", %{
    queue: queue,
    failure_queue: failure_queue
  } do
    job = fn -> throw("intentional crash") end |> Honeydew.async(queue, reply: true)

    assert {:moved, {"intentional crash", stacktrace}} = Honeydew.yield(job)
    assert is_list(stacktrace)

    :ok = Honeydew.start_workers(failure_queue, Stateless)

    # job ran in the failure queue
    assert {:error, {"intentional crash", _stacktrace}} = Honeydew.yield(job)
  end

  defp wait_for_queue(queue) do
    case Honeydew.status(queue) do
      %{queue: %{in_progress: in_progress}} when in_progress == 0 ->
        :ok

      _ ->
        :timer.sleep(100)
        wait_for_queue(queue)
    end
  end
end
