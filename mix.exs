defmodule Ogi.MixProject do
  use Mix.Project

  @source_url "https://github.com/PJUllrich/ogi"
  @version "0.2.1"

  def project do
    [
      app: :ogi,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      description: "Renders OpenGraph Images using Typst",
      package: package(),
      deps: deps(),
      docs: docs()
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
      {:typst, "~> 0.1"},
      {:plug, ">= 0.0.0"},
      {:quokka, "~> 2.8", only: [:dev, :test], runtime: false, optional: true},
      {:ex_doc, "~> 0.39", only: :dev, runtime: false, optional: true}
    ]
  end

  defp docs do
    [
      source_url: @source_url,
      api_reference: false,
      authors: ["Peter Ullrich"],
      assets: %{"assets" => "assets"},
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "examples/embedded-images.livemd",
        "examples/emojis.livemd",
        "examples/templates.livemd"
      ],
      groups_for_extras: [
        Examples: [~r"examples/"]
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    [
      name: "ogi",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
                CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
