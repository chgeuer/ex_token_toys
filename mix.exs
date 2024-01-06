defmodule AadRefresher.MixProject do
  use Mix.Project

  def project do
    [
      app: :aad_refresher,
      version: "0.1.0",
      elixir: "~> 1.16",
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
      {:ex_windows_api_dataprotection, "~> 0.1.2"},
      {:jason, "~> 1.4"},
      {:jsonrs, "~> 0.3.3"},
      {:req, "~> 0.4.8"},
      {:jose, "~> 1.11"},
      {:jose_utils, "~> 0.4.0"}
    ]
  end
end
