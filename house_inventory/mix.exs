defmodule HouseInventory.MixProject do
  use Mix.Project

  def project do
    [
      app: :house_inventory,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HouseInventory.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.9.0"},
      {:ecto_sqlite3, "~> 0.8.2"},
      {:ecto, "~> 3.9.0"}
    ]
  end
end
