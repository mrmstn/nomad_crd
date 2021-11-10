defmodule NomadCrd.TemplateRenderTest do
  use ExUnit.Case
  alias NomadClient.Api.Jobs
  alias NomadCrdTest.Templates.RedisV2

  @tag :external
  test "build_template" do
    id = "test-id"
    password = "password"

    variables = %{
      id: id,
      password: password
    }

    expected = %NomadClient.Model.Job{
      Datacenters: ["dc1"],
      ID: id,
      Name: id,
      TaskGroups: [
        %NomadClient.Model.TaskGroup{
          Name: "cache",
          Services: [],
          Tasks: [
            %NomadClient.Model.Task{
              Driver: "docker",
              Name: "redis",
              Config: %{
                "args" => ["/local/redis.conf"],
                "command" => "redis-server",
                "image" => "redis:6.2.6",
                "mount" => [%{"source" => "local", "target" => "/etc/redis.d", "type" => "bind"}]
              },
              Templates: [
                %NomadClient.Model.Template{
                  DestPath: "local/redis.conf",
                  EmbeddedTmpl: "requirepass password\n",
                  Envvars: false
                }
              ]
            }
          ]
        }
      ]
    }

    assert expected == NomadCrd.TemplateRender.render(RedisV2, variables)
  end
end
