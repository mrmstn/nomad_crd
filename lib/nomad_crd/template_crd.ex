defmodule NomadCrd.TemplateCrd do
  use GenServer

  defmodule State do
    defstruct [
      :backend,
      :rendering,
      :diff_engine,
      :template,
      :delta,
      :job_filter_fn
    ]

    @type t :: %__MODULE__{
            :backend => NomadCrd.Backend,
            :rendering => NomadCrd.TemplateRender,
            :diff_engine => NomadCrd.DiffEngines.TemplateDiff,
            :template => NomadCrd.Template,
            :delta => %{optional(any) => {NomadClient.Model.Job.t(), map()}},
            :job_filter_fn => (NomadClient.Model.Job.t() -> true | false) | nil
          }
  end

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) when is_list(opts) do
    state = %State{
      backend: Keyword.fetch!(opts, :backend),
      rendering: Keyword.get(opts, :rendering, NomadCrd.TemplateRender),
      diff_engine: Keyword.get(opts, :diff_engine, NomadCrd.DiffEngines.TemplateDiff),
      template: Keyword.fetch!(opts, :template),
      job_filter_fn: Keyword.get(opts, :job_filter_fn, nil)
    }

    name = Keyword.get(opts, :name, state.template)

    IO.inspect(opts, label: "CRD Name")

    GenServer.start_link(__MODULE__, state, name: name)
  end

  def create(pid, variables) do
    GenServer.call(pid, {:create, variables}, 60_000)
  end

  def get_diff(pid) do
    GenServer.call(pid, :check_diff)
  end

  def delete(pid, id) do
    GenServer.call(pid, {:delete, id})
  end

  def update_all(pid) do
    GenServer.call(pid, {:update, :all}, 60_000)
  end

  # Server (callbacks)

  def init(%State{} = state) do
    {:ok, state}
  end

  def handle_call({:create, variables}, _from, %State{} = state) do
    job_def = state.rendering.render(state.template, variables)
    response = state.backend.create_job(job_def)

    {:reply, response, state}
  end

  def handle_call({:delete, id}, _from, %State{} = state) do
    response = state.backend.delete_job(id)

    {:reply, response, state}
  end

  # ------------------------[EVERY HANDLE CALL DOWN HERE REQUIRES A DELTA]------------------------
  def handle_call(action, from, %State{delta: nil} = state) do
    state = load_delta(state)

    handle_call(action, from, state)
  end

  def handle_call(:check_diff, _from, %State{delta: delta} = state) do
    diff =
      delta
      |> Enum.map(fn {id, {_job, diff}} ->
        {id, diff}
      end)
      |> Enum.reject(fn {_id, diff} -> %{} === diff end)
      |> Map.new()

    {:reply, diff, state}
  end

  def handle_call({:update, :all}, _from, %State{delta: delta} = state) do
    task_results =
      delta
      |> Task.async_stream(
        fn
          {_id, {job, diff}} when diff === %{} ->
            # noop for empty delta
            {:ok, job}

          {_id, {job, diff}} ->
            job_id = Map.get(job, :ID)
            job_update = state.diff_engine.patch(job, diff)
            state.backend.update_job(job_id, job_update)
        end,
        timeout: 60_000
      )
      |> Enum.to_list()

    # TODO: Let's just be honest ... this is kind of lazy and garabage, sorry future me.
    # TODO: Do propper error handling.
    status =
      task_results
      |> Enum.all?(fn
        {:ok, {:ok, _job}} -> true
        _ -> false
      end)
      |> if do
        :ok
      else
        :error
      end

    {:reply, status, invalidate_delta(state)}
  end

  def handle_info(:reload_delta, %State{} = state) do
    {:noreply, load_delta(state)}
  end

  defp load_delta(%State{} = state) do
    alias NomadClient.Model.Job

    {:ok, jobs} = get_suitable_jobs(state)

    delta =
      jobs
      |> Enum.map(fn %Job{} = job ->
        id = Map.get(job, :ID)

        diff = state.diff_engine.diff(job, state.template)

        {id, {job, diff}}
      end)
      |> Map.new()

    %{state | delta: delta}
  end

  defp get_suitable_jobs(%State{job_filter_fn: nil} = state), do: state.backend.get_jobs()

  defp get_suitable_jobs(%State{job_filter_fn: filter_fn} = state) do
    {:ok, jobs} = state.backend.get_jobs()
    jobs = Enum.filter(jobs, filter_fn)
    {:ok, jobs}
  end

  defp invalidate_delta(%State{} = state), do: %{state | delta: nil}
end
