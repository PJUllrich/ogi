defmodule Ogi.MixProject do
  use Mix.Project

  def project do
    [
      app: :ogi,
      version: "0.2.1",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      description: "Renders OpenGraph Images using Typst",
      package: package(),
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
      {:typst, "~> 0.1"},
      {:plug, ">= 0.0.0"},
      {:quokka, "~> 2.8", only: [:dev, :test], runtime: false, optional: true},
      {:ex_doc, "~> 0.39", only: :dev, runtime: false, optional: true}
    ]
  end

  defp package do
    [
      name: "ogi",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
                CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pjullrich/ogi"}
    ]
  end
end
