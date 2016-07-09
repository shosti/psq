defmodule PSQ.Mixfile do
  use Mix.Project

  def project do
    [app: :psq,
     version: "0.0.1",
     elixir: "> 1.2.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     dialyzer: [
       flags: ~w(-Wunmatched_returns -Werror_handling -Wrace_conditions -Wunderspecs -Wno_match),
       plt_file: "#{System.user_home!}/.plt/dialyxir_#{:erlang.system_info(:otp_release)}_#{System.version}.plt"]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:excheck, "~> 0.3", only: :test},
      {:triq, github: "shosti/triq", only: :test},
      {:benchfella, "~> 0.3.0", only: :dev},
      {:dialyxir, "~> 0.3.5", only: :dev},
    ]
  end
end
