defmodule NomadCrd.Templates.RedisTempalte do
  alias NomadClient.Model
  alias NomadClient.Model.Job

  def name(), do: "redis-spec"

  def variables() do
    [
      :id,
      :password
    ]
  end

  def template() do
    %Job{
      Datacenters: ["dc1"],
      ID: {:var, :id},
      Name: {:var, :id},
      TaskGroups: [
        build_task_group()
      ]
    }
  end

  defp build_task_group() do
    %Model.TaskGroup{
      Name: "cache",
      Services: [],
      Tasks: [
        build_task()
      ]
    }
  end

  defp build_task() do
    embedded_tmpl = fn vars ->
      """
      requirepass %{vars.password}
      """
    end

    template = %Model.Template{
      EmbeddedTmpl: {:var, embedded_tmpl},
      Envvars: false,
      DestPath: "local/redis.conf"
    }

    %Model.Task{
      Config: %{
        "image" => "redis:6.2.6",
        "mount" => [
          %{
            "type" => "bind",
            "source" => "local",
            "target" => "/etc/redis.d"
          }
        ],
        "command" => "redis-server",
        "args" => [
          "/local/redis.conf"
        ]
      },
      Driver: "docker",
      Name: "redis",
      Templates: [template]
    }
  end
end
