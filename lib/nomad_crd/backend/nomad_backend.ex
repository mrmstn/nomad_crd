defmodule NomadCrd.NomadBackend do
  alias NomadClient.Api
  alias NomadClient.Model

  @wait_timeout 30_000
  @watch_sleep 1_000

  @spec create_job(%Model.Job{}) :: {:ok, %Model.Job{}}
  def create_job(%Model.Job{} = job) do
    payload = %Model.RegisterJobRequest{Job: job}
    conn = conn()

    conn
    |> Api.Jobs.register_job(payload)
    |> handle_response()
  end

  def update_job(job_id, job_update) do
    conn = conn()

    job_update = Map.put(job_update, :ID, job_id)
    payload = %Model.RegisterJobRequest{Job: job_update}

    Api.Jobs.update_job(conn, job_id, payload)
    |> handle_response()
  end

  defp handle_response({:ok, %Model.JobRegisterResponse{EvalID: eval_id}}) do
    conn = conn()

    {:ok, %Model.Evaluation{} = eval} = wait_for_deployment_id(eval_id, 5_000)

    eval
    |> Map.fetch!(:DeploymentID)
    |> wait_for_ready_status(@wait_timeout)
    |> case do
      {:ok, deployment} ->
        job_id = Map.get(deployment, :JobID)
        Api.Jobs.get_job(conn, job_id)

      {:error, :timeout} ->
        {:error, :timeout, eval}
    end
  end

  defp conn do
    # TODO: Must be configurable...
    NomadClient.Connection.new()
  end

  defp wait_for_deployment_id(eval_id, timeout) when is_binary(eval_id) do
    conn = conn()

    wait_for(
      fn -> Api.Evaluations.get_evaluation(conn, eval_id) end,
      fn {:ok, %{DeploymentID: deployment_id}} -> is_binary(deployment_id) end,
      timeout
    )
  end

  defp wait_for_ready_status(deployment_id, timeout) when is_binary(deployment_id) do
    conn = conn()

    wait_for(
      fn -> Api.Deployments.get_deployment(conn, deployment_id) end,
      fn {:ok, %{Status: status}} -> status == "successful" end,
      timeout
    )
  end

  defp wait_for(prepare_fn, condition_fn, timeout) do
    task =
      fn -> wait_for(prepare_fn, condition_fn) end
      |> Task.async()

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} ->
        result

      nil ->
        require Logger
        Logger.warn("Failed to get a result in #{timeout}ms")
        {:error, :timeout}
    end
  end

  defp wait_for(prepare_fn, condition_fn) do
    result = prepare_fn.()

    if condition_fn.(result) !== true do
      :timer.sleep(@watch_sleep)
      wait_for(prepare_fn, condition_fn)
    else
      result
    end
  end
end
