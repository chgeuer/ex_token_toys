defmodule AadRefresher.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_token_toys,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :fs, :observer, :wx, :runtime_tools, :xmerl],
      mod: {MsalTokenCache, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_windows_api_dataprotection, "~> 0.1.2"},
      {:jason, "~> 1.4"},
      {:jsonrs, "~> 0.3.3"},
      {:finch, "~> 0.17.0"},
      {:req, "~> 0.4.8"},
      {:jose, "~> 1.11"},
      {:jose_utils, "~> 0.4.0"},
      {:fs, "~> 8.6"},
      {:bandit, "~> 1.1"},
      {:kino, "~> 0.12.3"}
    ]
  end
end
