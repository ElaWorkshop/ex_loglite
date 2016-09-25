defmodule ExLogLite.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_loglite,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application, do: []

  defp deps, do: []
end
