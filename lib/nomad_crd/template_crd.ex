defmodule NomadCrd.TemplateCrd do
  defmodule State do
    defstruct [
      :backend,
      :rendering,
      :diff_engine,
      :template
    ]
  end

  def start_link(opts) when is_list(opts) do
    template = Keyword.fetch!(opts, :template)
    name = Keyword.get(opts, :name, template)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def create(pid, variables) do
    GenServer.cast(pid, {:create, variables})
  end

  def get_diff(pid) do
    GenServer.cast(pid, :check_diff)
  end

  # Server (callbacks)

  @impl true
  def init(%State{} = state) do
    {:ok, stategit}
  end

  @impl true
  def handle_call({:create, variables}, _from, %State{} = state) do
    job_def = state.rendering.render(state.template, variables)
    {:ok, job} = state.backend.create_job(job_def)

    {:reply, job, state}
  end

  @impl true
  def handle_call(:check_diff, %State{} = state) do
    diff = check_diff(state)

    {:reply, diff, state}
  end

  defp check_diff(%State{} = state) do
    {:ok, jobs} = state.backend.get_jobs()

    diff =
      jobs
      |> Enum.map(fn job ->
        state.diff_engine.diff(job, state.template)
      end)
  end
end
