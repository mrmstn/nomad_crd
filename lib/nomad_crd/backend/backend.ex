defmodule NomadCrd.Backend do
  @callback create_job() :: {:ok, [binary()]} | {:error, term()}
  @callback get_jobs() :: {:ok, [binary()]} | {:error, term()}
  @callback update_job() :: nil
end
