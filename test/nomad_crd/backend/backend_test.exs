defmodule NomadCrd.BackendTest do
  use ExUnit.Case

  alias NomadClient.Model
  alias NomadCrd.DiffEngines.TemplateDiff
  alias NomadCrdTest.Templates.RedisV1

  @backend NomadCrd.NomadBackend
  @rendering NomadCrd.TemplateRender
  # @diff_engine NomadCrd.DiffEngines.TemplateDiff

  @tag :external
  test "flow" do
    init_job = get_job()

    # deploy_job = null
    {:ok, %Model.Job{} = job} = @backend.create_job(init_job)

    # get_deployed_job = null
    # @diff_engine.extract_update_patch(job)

    update_patch = %{
      TaskGroups: [%{Tasks: [%{Config: %{"image" => "redis:6"}}]}]
    }

    job_id = Map.get(job, :ID)
    patched_deployment = TemplateDiff.patch(job, update_patch)

    @backend.update_job(job_id, patched_deployment)

    # change_template = null

    # extract_diff = null

    # update_deployment = null

    # assert_updated_deployment = null
  end

  @spec get_job() :: Model.Job
  defp get_job do
    id = "test-id"
    password = "password"

    variables = %{
      id: id,
      password: password
    }

    RedisV1
    |> @rendering.render(variables)
  end
end
