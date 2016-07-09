# PSQ [![Build Status](https://travis-ci.org/shosti/psq.svg?branch=master)](https://travis-ci.org/shosti/psq)

A priority search queue implementation in Elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add psq to your list of dependencies in `mix.exs`:

        def deps do
          [{:psq, "~> 0.0.1"}]
        end

  2. Ensure psq is started before your application:

        def application do
          [applications: [:psq]]
        end
