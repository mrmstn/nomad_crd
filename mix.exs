defmodule NomadCrd.MixProject do
  use Mix.Project

  @package_name :nomad_crd
  @source_url "https://github.com/mrmstn/nomad_crd"
  @version "0.1.3"

  def project do
    [
      app: @package_name,
      version: @version,
      elixir: "~> 1.12",
      config_path: "config/config.exs",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: "A Resource Manager for HashiCorp Nomad.",
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
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:dotenvy, "~> 0.5.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:hackney, "~> 1.13", only: [:dev, :test]},
      {:faker, "~> 0.16.0", only: :test},
      {:map_diff, "~> 1.3"},
      {:nomad_client, "~> 0.12.0"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package() do
    [
      maintainers: ["Michael Ramstein"],
      files: ~w(lib mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
