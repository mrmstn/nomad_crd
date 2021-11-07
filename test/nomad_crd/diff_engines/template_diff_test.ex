defmodule NomadCrd.DiffEngines.TemplateDiffTest do
  use ExUnit.Case
  alias NomadClient.Api.Jobs
  alias NomadClient.Connection
  alias NomadCrd.DiffEngines.TemplateDiff
  alias NomadCrd.Templates.RedisTempalte

  test "detect_changes" do
    template = RedisTempalte.template()

    deployed = %NomadClient.Model.Job{
      Datacenters: ["dc1"],
      ID: "1",
      Name: "1",
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
                "image" => "redis:6.2.0",
                "mount" => [%{"source" => "local", "target" => "/etc/redis.d", "type" => "bind"}]
              },
              Templates: [
                %NomadClient.Model.Template{
                  DestPath: "local/redis.conf",
                  EmbeddedTmpl: "requirepass secure-passwords-are-important!\n",
                  Envvars: false
                }
              ]
            }
          ]
        }
      ]
    }

    expected = %{
      TaskGroups: [%{Tasks: [%{Config: %{"image" => "redis:6.2.6"}, Templates: [%{}]}]}]
    }

    assert expected == TemplateDiff.extract_update_patch(deployed, template)
  end
end
