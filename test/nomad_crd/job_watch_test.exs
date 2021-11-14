defmodule NomadCrd.JobWatchTest do
  use ExUnit.Case
  alias NomadCrd.DiffEngines.TemplateDiff
  alias NomadCrdTest.Templates.RedisV1
  alias NomadCrdTest.Templates.RedisV2

  test "detect_changes" do
    template = RedisV2.template()

    deployed = get_deployed_example(RedisV1)

    expected = %{
      TaskGroups: [%{Tasks: [%{Config: %{"image" => "redis:6.2.6"}}]}]
    }

    assert expected == TemplateDiff.extract_update_patch(deployed, template)
  end

  defp get_deployed_example(RedisV1) do
    %NomadClient.Model.Job{
      AllAtOnce: false,
      ConsulToken: "",
      CreateIndex: 10,
      Datacenters: ["dc1"],
      Dispatched: false,
      ID: "test-id",
      JobModifyIndex: 417,
      ModifyIndex: 424,
      Name: "test-id",
      Namespace: "default",
      ParentID: "",
      Priority: 50,
      Region: "global",
      Stable: true,
      Status: "running",
      StatusDescription: "",
      Stop: false,
      SubmitTime: 1_636_553_900_418_385_047,
      TaskGroups: [
        %NomadClient.Model.TaskGroup{
          Count: 1,
          EphemeralDisk: %NomadClient.Model.EphemeralDisk{
            Migrate: false,
            SizeMB: 300,
            Sticky: false
          },
          Migrate: %NomadClient.Model.MigrateStrategy{
            HealthCheck: "checks",
            HealthyDeadline: 300_000_000_000,
            MaxParallel: 1,
            MinHealthyTime: 10_000_000_000
          },
          Name: "cache",
          ReschedulePolicy: %NomadClient.Model.ReschedulePolicy{
            Attempts: 0,
            Delay: 30_000_000_000,
            DelayFunction: "exponential",
            Interval: 0,
            MaxDelay: 3_600_000_000_000,
            Unlimited: true
          },
          RestartPolicy: %NomadClient.Model.RestartPolicy{
            Attempts: 2,
            Delay: 15_000_000_000,
            Interval: 1_800_000_000_000,
            Mode: "fail"
          },
          Tasks: [
            %NomadClient.Model.Task{
              Templates: [
                %NomadClient.Model.Template{
                  DestPath: "local/redis.conf",
                  EmbeddedTmpl: """
                  requirepass this-is-super-secure!
                  """,
                  Envvars: false
                }
              ],
              Driver: "docker",
              Name: "redis",
              Config: %{
                "args" => ["/local/redis.conf"],
                "command" => "redis-server",
                "image" => "redis:6.0.16",
                "mount" => [%{"source" => "local", "target" => "/etc/redis.d", "type" => "bind"}]
              }
            }
          ],
          Update: %NomadClient.Model.UpdateStrategy{
            AutoPromote: false,
            AutoRevert: false,
            Canary: 0,
            HealthCheck: "checks",
            HealthyDeadline: 300_000_000_000
          }
        }
      ],
      Type: "service",
      Update: %NomadClient.Model.UpdateStrategy{
        AutoPromote: false,
        AutoRevert: false,
        Canary: 0,
        HealthCheck: "",
        HealthyDeadline: 0,
        MaxParallel: 1,
        MinHealthyTime: 0,
        ProgressDeadline: 0,
        Stagger: 30_000_000_000
      },
      VaultToken: "",
      Version: 2
    }
  end
end
