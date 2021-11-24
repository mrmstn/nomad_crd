defmodule NomadCrd.TemplateCrdTest do
  use ExUnit.Case
  alias NomadCrd.TemplateCrd
  alias NomadCrdTest.Templates.RedisV1
  alias NomadCrdTest.Templates.RedisV2

  @backend NomadCrd.NomadBackend

  setup %{} do
    opts = [
      backend: @backend,
      rendering: NomadCrd.TemplateRender,
      diff_engine: NomadCrd.DiffEngines.TemplateDiff,
      template: RedisV2
    ]

    {:ok, pid} = start_supervised({NomadCrd.TemplateCrd, opts})
    {:ok, [pid: pid]}
  end

  test "PID == Template", %{pid: pid} do
    template_pid = Process.whereis(RedisV2)
    assert is_pid(template_pid)

    assert pid == template_pid
  end

  test "create", %{pid: pid} do
    id = "strong-id"
    vars = %{id: id, password: "my-secure-password"}
    {:ok, job_def} = TemplateCrd.create(pid, vars)

    assert id == Map.get(job_def, :ID)
  end

  test "diff", %{pid: pid} do
    job_id = "unique-id"
    deploy_dirty_job(job_id)
    expected = dirty_job_diff(RedisV2)

    %{^job_id => job_diff} = TemplateCrd.get_diff(pid)

    assert job_diff === expected
  end

  test "delete", %{pid: pid} do
    job_id = "delete-me"

    job =
      NomadCrd.TemplateRender.render(
        RedisV1,
        %{id: job_id, password: "my-secure-password"}
      )

    _deployed_job = @backend.create_job(job)

    {:ok, deleted_job} = TemplateCrd.delete(pid, job_id)
    assert true == Map.get(deleted_job, :Stop)
    assert "dead" == Map.get(deleted_job, :Status)
  end

  @tag timeout: 120_000
  test "update dirty jobs", %{pid: pid} do
    # First, deploy some dirty Jobs
    0..4
    |> Task.async_stream(&deploy_dirty_job("update-dirty-#{&1}"), timeout: 30_000)
    |> Enum.to_list()

    diff = TemplateCrd.get_diff(pid)

    [_, _, _, _, _] =
      for {"update-dirty-" <> _, diff} <- diff do
        assert %{} !== diff
      end

    :ok = TemplateCrd.update_all(pid)
    assert %{} == TemplateCrd.get_diff(pid)
  end

  test "filter", %{pid: pid} do
    alias NomadClient.Model.Job

    template = RedisV2
    ref = RedisV2.Filtered
    filter_prefix = "filter-prefix"

    opts = [
      backend: @backend,
      rendering: NomadCrd.TemplateRender,
      diff_engine: NomadCrd.DiffEngines.TemplateDiff,
      template: RedisV2,
      job_filter_fn: fn %Job{ID: id} -> String.starts_with?(id, filter_prefix) end,
      name: ref
    ]

    spec = NomadCrd.TemplateCrd.child_spec(opts)

    {:ok, filter_pid} = start_supervised(%{spec | id: ref})

    {:ok, _job} = deploy_dirty_job(filter_prefix)
    {:ok, _job} = deploy_dirty_job("excluded-job")

    full_diff = TemplateCrd.get_diff(pid)
    filtered_diff = TemplateCrd.get_diff(filter_pid)

    dirty_diff = dirty_job_diff(template)

    assert filtered_diff === %{"filter-prefix" => dirty_diff}
    assert full_diff === %{"filter-prefix" => dirty_diff, "excluded-job" => dirty_diff}
  end

  defp deploy_dirty_job(nil) do
    id = Faker.String.base64(8)
    deploy_dirty_job("dirty-" <> id)
  end

  defp deploy_dirty_job(job_id) do
    job =
      NomadCrd.TemplateRender.render(
        RedisV1,
        %{id: job_id, password: Faker.String.base64(21)}
      )

    @backend.create_job(job)
  end

  defp dirty_job_diff(RedisV2) do
    %{
      TaskGroups: [
        %{
          Tasks: [
            %{
              Config: %{
                "args" => [{:no_change}, {:del, ["--port", "7777"]}],
                "image" => "redis:6.2.6"
              }
            }
          ]
        }
      ]
    }
  end
end
