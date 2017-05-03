defmodule ExLogLite.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_loglite,
     version: "0.1.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     description: description()]
  end

  def application, do: []

  defp deps, do: [{:ex_doc, "~> 0.13", only: :dev}]

  defp description, do: "An Elixir Logger Backend for EVE LogLite."

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Lou Xun <aquarhead@ela.build>"],
      links: %{"GitHub" => "https://github.com/ElaWorkshop/ex_loglite"}
    ]
  end
end
