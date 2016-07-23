# PSQ [![Build Status](https://travis-ci.org/shosti/psq.svg?branch=master)](https://travis-ci.org/shosti/psq)[![Coverage Status](https://coveralls.io/repos/github/shosti/psq/badge.svg)](https://coveralls.io/github/shosti/psq)

Priority search queues for Elixir.

## Installation

Add psq to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:psq, "~> 0.1.0"}]
end
```

## Usage

See [the docs](https://hexdocs.pm/psq/0.1.0/PSQ.html) for usage and examples.

## Implementation

The implementation uses priority-search pennants as described in
[this paper](https://www.cs.ox.ac.uk/people/ralf.hinze/publications/UU-CS-2001-09.pdf),
with very few modifications. Internally, tuples are used to represent nodes in
the winner/loser tree (since they offered a significant performance boost over
structs).

Testing uses the excellent [excheck](https://github.com/parroty/excheck) library
for QuickCheck-style tests; benchmarking uses
[Benchee](https://github.com/PragTob/benchee).

## Contributing

Contributions welcome! I'd particularly welcome:

1. *Suggestions for improving the interface.* I did my best to make it
   "elixir-y", but I haven't used it enough to know if the interface makes sense
   for a variety of use-cases.

2. *Performance optimizations.* Making a queue with 10 million entries is viable
   but takes quite a long time (~120s on my machine, vs ~10s for sorting the
   equivalent list). I'd love to get the time to build a queue be roughly
   equivalent to the time to sort a list. If you want to play around with that
   stuff, be sure to use run the benchmarks before and after (`mix run
   bench/bench.exs`).
