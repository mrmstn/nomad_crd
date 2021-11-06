defmodule NomadCrd.MixProject do
  use Mix.Project

  def project do
    [
      app: :nomad_crd,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nomad_client, "~> 0.12.0"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dotenvy, "~> 0.5.0", only: [:dev, :test]}
    ]
  end
end
