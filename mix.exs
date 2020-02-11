defmodule Kvasir.Redis.MixProject do
  use Mix.Project
  @version "0.0.3"

  def project do
    [
      app: :kvasir_redis,
      description: "Redis [event] source, [cold] storage, and agent cache for Kvasir.",
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # dialyzer: [ignore_warnings: "dialyzer.ignore-warnings", plt_add_deps: true],

      # Docs
      name: "kvasir_redis",
      source_url: "https://github.com/IanLuites/kvasir_redis",
      homepage_url: "https://github.com/IanLuites/kvasir_redis",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def package do
    [
      name: :kvasir_redis,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        # Elixir
        "lib/kvasir_redis",
        ".formatter.exs",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      links: %{
        "GitHub" => "https://github.com/IanLuites/kvasir_redis"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kvasir, git: "https://github.com/IanLuites/kvasir", branch: "release/v1.0"},
      {:kvasir_agent,
       git: "https://github.com/IanLuites/kvasir_agent", branch: "release/v1.0", optional: true},
      {:raditz, "~> 0.0.7"}
    ]
  end
end
