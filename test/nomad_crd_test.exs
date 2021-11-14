defmodule NomadCrdTest do
  use ExUnit.Case
  alias NomadClient.Model
  alias NomadCrdTest.Templates.RedisV1

  @backend NomadCrd.NomadBackend
  @rendering NomadCrd.TemplateRender
  @diff_engine NomadCrd.DiffEngines.TemplateDiff

  doctest NomadCrd

  test "greets the world" do
    assert NomadCrd.hello() == :world
  end

  test "Full Flow Test" do
    template = RedisV1
    initial_job = init_template(template)
    {:ok, %Model.Job{} = deployed_job} = @backend.create_job(initial_job)

    assert %{} === @diff_engine.diff(deployed_job, template)
  end

  defp init_template(template) do
    id = "test-id"
    password = "password"

    variables = %{
      id: id,
      password: password
    }

    @rendering.render(template, variables)
  end
end
