defmodule RsTxSupport.DiscMnesiaQueueIntegrationTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Honeydew.Job

  @moduletag :capture_log

  @num_workers 5

  setup [
    :setup_queue_name,
    :setup_queue,
    :setup_worker_pool
  ]

  describe "async/3" do
    test "sanity check", %{queue: queue} do
      %Job{} = {:send_msg, [self(), :hi]} |> Honeydew.async(queue)
      assert_receive :hi
    end

    test "persisted jobs smoke test", %{queue: queue} do
      num = 10_00

      me = self()

      0..num
      |> Task.async_stream(fn i ->
        %Job{} = {:send_msg, [me, i]} |> Honeydew.async(queue)
      end)
      |> Stream.run()

      Application.stop(:honeydew)

      :timer.sleep(1_000)

      Application.start(:honeydew)

      start_queue(queue)

      assert queue
             |> Honeydew.status()
             |> get_in([:queue, :count]) >
               0

      start_worker_pool(queue)

      wait_for_queue(queue)

      Enum.each(0..num, fn i ->
        assert_receive ^i
      end)
    end

    test "hammer smoke test", %{queue: queue} do
      num = 10_00

      me = self()

      0..num
      |> Task.async_stream(fn i ->
        %Job{} = {:send_msg, [me, i]} |> Honeydew.async(queue)
      end)
      |> Stream.run()

      wait_for_queue(queue)

      Enum.each(0..num, fn i ->
        assert_receive ^i
      end)
    end

    @tag :skip_worker_pool
    test "when queue doesn't exist" do
      assert_raise RuntimeError, fn ->
        Honeydew.async({:send_msg, [self(), :hi]}, :nonexistent_queue)
      end
    end

    test "delay_secs", %{queue: queue} do
      %Job{} = {:send_msg, [self(), :delay_test]} |> Honeydew.async(queue, delay_secs: 2)
      enqueued_at = DateTime.utc_now()

      receive do
        :delay_test ->
          assert DateTime.diff(DateTime.utc_now(), enqueued_at) == 2
      end
    end
  end

  test "yield/2", %{queue: queue} do
    first_job = {:return, [:hi]} |> Honeydew.async(queue, reply: true)
    second_job = {:return, [:there]} |> Honeydew.async(queue, reply: true)

    assert {:ok, :hi} = Honeydew.yield(first_job)
    assert {:ok, :there} = Honeydew.yield(second_job)
  end

  test "yield/2 when job isn't started properly", %{queue: queue} do
    job = Honeydew.async({:return, [:hi]}, queue)

    assert_raise ArgumentError, ~r/set `:reply` to `true`/i, fn ->
      Honeydew.yield(job)
    end
  end

  test "when yield/2 is called from a separate process", %{queue: queue} do
    job =
      fn ->
        Honeydew.async({:return, [:hi]}, queue, reply: true)
      end
      |> Task.async()
      |> Task.await()

    assert_raise ArgumentError, ~r/the owner/i, fn ->
      Honeydew.yield(job)
    end
  end

  test "suspend/1", %{queue: queue} do
    Honeydew.suspend(queue)
    {:send_msg, [self(), :hi]} |> Honeydew.async(queue)
    assert Honeydew.status(queue) |> get_in([:queue, :count]) == 1
    assert Honeydew.status(queue) |> get_in([:queue, :suspended]) == true
    refute_receive :hi
  end

  @tag :start_suspended
  test "starting a queue suspended", %{queue: queue} do
    {:send_msg, [self(), :hi]} |> Honeydew.async(queue)
    assert Honeydew.status(queue) |> get_in([:queue, :count]) == 1
    assert Honeydew.status(queue) |> get_in([:queue, :suspended]) == true
    refute_receive :hi
  end

  test "resume/1", %{queue: queue} do
    Honeydew.suspend(queue)
    {:send_msg, [self(), :hi]} |> Honeydew.async(queue)
    refute_receive :hi
    Honeydew.resume(queue)
    assert_receive :hi
    assert Honeydew.status(queue) |> get_in([:queue, :suspended]) == false
  end

  test "status/1", %{queue: queue} do
    {:sleep, [1_000]} |> Honeydew.async(queue)
    Honeydew.suspend(queue)
    Enum.each(1..3, fn _ -> {:send_msg, [self(), :hi]} |> Honeydew.async(queue) end)
    assert %{queue: %{count: 4, in_progress: 1, suspended: true}} = Honeydew.status(queue)
  end

  test "filter/1", %{queue: queue} do
    Honeydew.suspend(queue)

    {:sleep, [1_000]} |> Honeydew.async(queue)
    {:sleep, [2_000]} |> Honeydew.async(queue)
    {:sleep, [2_000]} |> Honeydew.async(queue)
    Enum.each(1..3, fn i -> {:send_msg, [self(), i]} |> Honeydew.async(queue) end)

    jobs =
      Honeydew.filter(queue, fn
        %Job{task: {:sleep, [2_000]}} -> true
        _ -> false
      end)

    assert Enum.count(jobs) == 2

    Enum.each(jobs, fn job ->
      assert Map.get(job, :task) == {:sleep, [2_000]}
    end)
  end

  test "filter/1 supports :mnesia.match_object/1", %{queue: queue} do
    Honeydew.suspend(queue)

    {:sleep, [1_000]} |> Honeydew.async(queue)
    {:sleep, [2_000]} |> Honeydew.async(queue)
    {:sleep, [2_000]} |> Honeydew.async(queue)
    Enum.each(1..3, fn i -> {:send_msg, [self(), i]} |> Honeydew.async(queue) end)

    jobs = Honeydew.filter(queue, %{task: {:sleep, [2_000]}})
    assert Enum.count(jobs) == 2

    Enum.each(jobs, fn job ->
      assert Map.get(job, :task) == {:sleep, [2_000]}
    end)
  end

  test "cancel/1 when job hasn't executed", %{queue: queue} do
    Honeydew.suspend(queue)

    assert :ok =
             {:send_msg, [self(), :hi]}
             |> Honeydew.async(queue)
             |> Honeydew.cancel()

    Honeydew.resume(queue)

    refute_receive :hi
  end

  test "cancel/1 when job is in progress", %{queue: queue} do
    me = self()

    assert {:error, :in_progress} =
             fn ->
               Process.sleep(50)
               send(me, :hi)
             end
             |> Honeydew.async(queue)
             |> Honeydew.cancel()

    assert_receive :hi
  end

  test "cancel/1 when has been processed", %{queue: queue} do
    job = Honeydew.async({:send_msg, [self(), :hi]}, queue)

    receive do
      :hi -> :ok
    end

    # Wait for job to be acked
    Process.sleep(100)

    assert {:error, :not_found} = Honeydew.cancel(job)
  end

  test "pause queue, enqueue many, filter and cancel some, resume queue", %{queue: queue} do
    Honeydew.suspend(queue)

    Enum.each(0..10, &Honeydew.async({:send_msg, [self(), &1]}, queue))

    Honeydew.filter(queue, fn job ->
      {:send_msg, [_, i]} = job.task
      rem(i, 2) == 0
    end)
    |> Enum.each(&Honeydew.cancel(&1))

    Honeydew.resume(queue)

    Enum.each([0, 2, 4, 6, 8, 10], fn i ->
      refute_receive ^i
    end)

    Enum.each([1, 3, 5, 7, 9], fn i ->
      assert_receive ^i
    end)
  end

  test "should not leak monitors", %{queue: queue} do
    queue_process = Honeydew.get_queue(queue)

    Enum.each(0..500, fn _ ->
      me = self()
      fn -> send(me, :hi) end |> Honeydew.async(queue)
      assert_receive :hi
    end)

    {:monitors, monitors} = :erlang.process_info(queue_process, :monitors)
    assert Enum.count(monitors) < 20
  end

  test "resets in-progress jobs after crashing", %{queue: queue} do
    Enum.each(1..10, fn _ ->
      Honeydew.async(fn -> Process.sleep(20_000) end, queue)
    end)

    %{queue: %{count: total, in_progress: in_progress}} = Honeydew.status(queue)

    assert total == 10
    assert in_progress == @num_workers

    :ok = Honeydew.stop_queue(queue)
    :ok = Honeydew.stop_workers(queue)

    :ok = start_queue(queue)

    %{queue: %{count: total, in_progress: in_progress}} = Honeydew.status(queue)

    assert total == 10
    assert in_progress == 0
  end

  @tag :skip_worker_pool
  test "when workers join a queue with existing jobs", %{queue: queue} do
    %Job{} = {:send_msg, [self(), :hi]} |> Honeydew.async(queue)

    start_worker_pool(queue)

    assert_receive :hi
  end

  @tag :skip_worker_pool
  test "when workers join a suspended queue with existing jobs", %{queue: queue} do
    %Job{} = {:send_msg, [self(), :hi]} |> Honeydew.async(queue)
    Honeydew.suspend(queue)

    start_worker_pool(queue)

    refute_receive :hi
  end

  @tag :skip_worker_pool
  test "when workers join a suspended queue with existing jobs and queue is resumed", %{
    queue: queue
  } do
    %Job{} = {:send_msg, [self(), :hi]} |> Honeydew.async(queue)
    Honeydew.suspend(queue)

    start_worker_pool(queue)
    refute_receive :hi

    Honeydew.resume(queue)

    assert_receive :hi
  end

  @tag :skip_worker_pool
  test "moving a job that has not been processed", %{queue: queue} do
    job = {:send_msg, [self(), :hi]} |> Honeydew.async(queue)

    other_queue = generate_queue_name()
    :ok = start_queue(other_queue)
    :ok = start_worker_pool(other_queue)

    assert %Job{queue: ^other_queue} = Honeydew.move(job, other_queue)

    assert 0 = queue |> Honeydew.status() |> get_in([:queue, :count])
    assert_receive :hi
  end

  test "moving a job that has been processed", %{queue: queue} do
    job = {:send_msg, [self(), :hi]} |> Honeydew.async(queue)

    other_queue = generate_queue_name()
    :ok = start_queue(other_queue)
    :ok = start_worker_pool(other_queue)

    assert %Job{queue: ^other_queue} = Honeydew.move(job, other_queue)

    assert 0 = queue |> Honeydew.status() |> get_in([:queue, :count])

    # It should receive a response from the original queue and new queue
    assert_receive :hi
    assert_receive :hi
  end

  @tag :skip_worker_pool
  test "moving a job with reply: true that has not been processed", %{queue: queue} do
    job = Honeydew.async({:return, [:pong]}, queue, reply: true)

    other_queue = generate_queue_name()
    :ok = start_queue(other_queue)
    :ok = start_worker_pool(other_queue)

    assert %Job{queue: ^other_queue} = Honeydew.move(job, other_queue)
    assert 0 = queue |> Honeydew.status() |> get_in([:queue, :count])

    # It should only receive the response once
    assert {:ok, :pong} = Honeydew.yield(job)
    assert is_nil(Honeydew.yield(job, 100))
  end

  test "moving a job with reply: true that has been processed", %{queue: queue} do
    job = Honeydew.async({:return, [:pong]}, queue, reply: true)

    other_queue = generate_queue_name()
    :ok = start_queue(other_queue)
    :ok = start_worker_pool(other_queue)

    assert %Job{queue: ^other_queue} = Honeydew.move(job, other_queue)

    # It should receive a response from the old queue and the new queue, but no
    # more
    assert {:ok, :pong} = Honeydew.yield(job)
    assert {:ok, :pong} = Honeydew.yield(job)
    assert is_nil(Honeydew.yield(job, 100))
  end

  @tag :skip_worker_pool
  test "moving a job to a queue that doesn't exist" do
    assert_raise RuntimeError, fn ->
      Honeydew.async({:send_msg, [self(), :hi]}, :nonexistent_queue)
    end
  end

  @tag :exponential_failure
  test "delay via nack", %{queue: queue} do
    {:crash, [self()]} |> Honeydew.async(queue)

    delays =
      Enum.map(0..3, fn _ ->
        receive do
          :job_ran ->
            DateTime.utc_now()
        end
      end)
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [a, b] -> DateTime.diff(b, a) end)

    # 2^0 - 1 -> 0 sec delay
    # 2^1 - 1 -> 1 sec delay
    # 2^2 - 1 -> 3 sec delay
    assert_in_delta Enum.at(delays, 0), 0, 1
    assert_in_delta Enum.at(delays, 1), 1, 1
    assert_in_delta Enum.at(delays, 2), 3, 1
  end

  defp setup_queue_name(%{queue: queue}), do: {:ok, [queue: queue]}
  defp setup_queue_name(_), do: {:ok, [queue: generate_queue_name()]}

  defp setup_worker_pool(%{skip_worker_pool: true}), do: :ok

  defp setup_worker_pool(%{queue: queue}) do
    :ok = start_worker_pool(queue)
  end

  defp setup_queue(%{queue: queue} = context) do
    :ok = Application.ensure_started(:honeydew)

    on_exit(fn ->
      table = ["honeydew", inspect(queue)] |> Enum.join("_") |> String.to_atom()

      in_progress_table =
        ["honeydew", inspect(queue), "in_progress"] |> Enum.join("_") |> String.to_atom()

      Honeydew.stop_queue(queue)

      :ok = Application.stop(:honeydew)

      :mnesia.clear_table(table)
      :mnesia.clear_table(in_progress_table)
    end)

    suspended = Map.get(context, :start_suspended, false)

    Application.stop(:mnesia)

    case context do
      %{exponential_failure: true} ->
        :ok =
          start_queue(queue,
            suspended: suspended,
            failure_mode: {Honeydew.FailureMode.ExponentialRetry, times: 3}
          )

      _ ->
        :ok = start_queue(queue, suspended: suspended)
    end
  end

  defp generate_queue_name do
    :erlang.monotonic_time() |> to_string
  end

  defp start_queue(queue, opts \\ []) do
    queue_opts =
      Keyword.merge(
        [queue: {RsTxSupport.DiscMnesiaQueue, disc_only_copies: [node()]}],
        opts
      )

    Honeydew.start_queue(queue, queue_opts)
  end

  defp start_worker_pool(queue) do
    Honeydew.start_workers(queue, RsTxSupport.Stateless, num: @num_workers)
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
