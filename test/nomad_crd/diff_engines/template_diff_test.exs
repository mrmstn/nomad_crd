defmodule NomadCrd.DiffEngines.TemplateDiffTest do
  use ExUnit.Case
  alias NomadClient.Api.Jobs
  alias NomadClient.Connection
  alias NomadCrd.DiffEngines.TemplateDiff
  alias NomadCrdTest.Templates.RedisV1
  alias NomadCrdTest.Templates.RedisV2

  describe "diff/2" do
    test "changed template" do
      deployed = get_deployed_example(RedisV1)

      expected = %{
        TaskGroups: [%{Tasks: [%{Config: %{"image" => "redis:6.2.6"}}]}]
      }

      assert expected == TemplateDiff.diff(deployed, RedisV2)
    end

    test "no changes" do
      deployed = get_deployed_example(RedisV1)
      assert %{} == TemplateDiff.diff(deployed, RedisV1)
    end
  end

  describe "patch/2" do
    test "green flow" do
      deployed = get_deployed_example(RedisV1)
      patch = %{TaskGroups: [%{Tasks: [%{Config: %{"image" => "redis:6.2.6"}}]}]}

      expected = patched_deployment()

      assert expected == TemplateDiff.patch(deployed, patch)
    end
  end

  describe "extract_update_patch/2" do
    test "compare rendered templates" do
      t1 = NomadCrd.TemplateRender.render(RedisV2, %{id: "Hallo 1", password: "Test 1"})
      t2 = NomadCrd.TemplateRender.render(RedisV2, %{id: "Hallo 2", password: "Test 2"})

      expected = %{
        ID: "Hallo 2",
        Name: "Hallo 2",
        TaskGroups: [%{Tasks: [%{Templates: [%{EmbeddedTmpl: "requirepass Test 2\n"}]}]}]
      }

      assert expected == TemplateDiff.extract_update_patch(t1, t2)
    end
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

  defp patched_deployment do
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
              Config: %{
                "args" => ["/local/redis.conf"],
                "command" => "redis-server",
                "image" => "redis:6.2.6",
                "mount" => [
                  %{"source" => "local", "target" => "/etc/redis.d", "type" => "bind"}
                ]
              },
              Driver: "docker",
              Name: "redis",
              Templates: [
                %NomadClient.Model.Template{
                  DestPath: "local/redis.conf",
                  EmbeddedTmpl: "requirepass this-is-super-secure!\n",
                  Envvars: false
                }
              ]
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
