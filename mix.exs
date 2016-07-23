defmodule PSQ.Mixfile do
  use Mix.Project

  def project do
    [
      app: :psq,
      version: "0.1.0",
      elixir: "> 1.2.0",
      description: description,
      package: package,
      deps: deps,
      dialyzer: [
        flags: ~w(-Wunmatched_returns -Werror_handling -Wrace_conditions -Wno_match),
        plt_file: "#{System.user_home!}/.plt/dialyxir_#{:erlang.system_info(:otp_release)}_#{System.version}.plt"
      ],
      test_coverage: [tool: ExCoveralls],
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:excheck, "~> 0.4", only: :test},
      {:triq, github: "shosti/triq", only: :test},
      {:excoveralls, "~> 0.5", only: :test},
      {:benchee, "~> 0.3", only: :dev},
      {:benchee_csv, "~> 0.3", only: :dev},
      {:dialyxir, "~> 0.3.5", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 0.4", only: [:dev, :test]},
    ]
  end

  defp description do
    """
    A priority search queue implementation for Elixir.
    """
  end

  defp package do
    [
      maintainers: ["Emanuel Evans <mail@emanuel.industries>"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/shosti/psq"},
    ]
  end
end
