defmodule Starship.Mixfile do
  use Mix.Project

  def project do
    [
      app: :starship,
      version: "0.0.1",
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      name: "Starship",
      source_url: "https://github.com/coby-spotim/starship",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      # elixirc_options: [warnings_as_errors: true],
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # The main page in the docs
      docs: [main: "Starship", extras: ["README.md"]],
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}, plt_add_deps: :transitive]
    ]
  end

  def application do
    [
      extra_applications: applications(Mix.env())
    ]
  end

  defp applications(:dev), do: applications(:all) ++ [:remixed_remix]
  defp applications(_all), do: [:ssl, :logger, :runtime_tools]

  def deps do
    [
      ## Testing and Development Dependencies
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:credo, "~> 1.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:remixed_remix, "~> 1.0.0", only: :dev}
    ]
  end

  defp package do
    [
      description: "High Performance Low Level Elixir Webserver",
      # These are the default files included in the package
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Coby Benveniste"],
      links: %{"GitHub" => "https://github.com/coby-spotim/starship"},
      licenses: ["MIT License"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      quality: ["format", "credo --strict", "dialyzer"],
      ci: ["test", "format --check-formatted", "credo --strict", "dialyzer --halt-exit-status"]
    ]
  end
end
