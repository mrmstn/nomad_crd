defmodule NomadCrd.Template do
  alias NomadClient.Model

  @callback template() :: Model.Job.t()
  @callback variables() :: [atom()]
end
