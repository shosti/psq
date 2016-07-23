# PSQ [![Build Status](https://travis-ci.org/shosti/psq.svg?branch=master)](https://travis-ci.org/shosti/psq)[![Coverage Status](https://coveralls.io/repos/github/shosti/psq/badge.svg)](https://coveralls.io/github/shosti/psq)

Priority search queues for Elixir.

## Installation

Add psq to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:psq, "~> 0.0.1"}]
end
```

## Usage

PSQ provides a purely-functional implementation of priority search queues. A
priority search queue is a data structure that efficiently supports both
associative operations (like those for `Map`) and priority-queue operations
(akin to heaps in imperative languages). The implementation is based on the
Haskell
[PSQueue](https://hackage.haskell.org/package/PSQueue-1.1/docs/Data-PSQueue.html)
package and the associated paper.

PSQs can be created from lists in O(n log n) time. Once created, the minimum
element (`min`) and size (`Enum.count`) can be accessed in O(1) time; most
other basic operations (including `get`, `pop`, and `push`, and `delete`) are
in O(log n).

PSQs implement `Enumerable` and `Collectable`, so all your favorite functions
from `Enum` and `Stream` should work as expected.

Each entry in a PSQ has an associated *priority* and *key*. Map-like
operations, such as `get`, use keys to find the entry; all entries in a PSQ
are unique by key. Ordered operations, such as `pop` and `Enum.to_list`, use
priority to determine order (with minimum first). Priorities need not be
unique by entry; entries with the same priority will be popped in unspecified
order.

### Examples

There are two primary ways to determine a value's priority and key in a
queue. The simplest is to start with an empty queue and input values with
priorities and keys directly, through `put/4`:

```elixir
iex> q = PSQ.new |> PSQ.put(:a, "foo", 2) |> PSQ.put(:b, "bar", 1)
iex> q |> PSQ.get(:a)
"foo"
iex> q |> PSQ.min
"bar"
```

Alternatively, you can specify mapper functions to determine key and priority
for all entries in the queue. This is particularly useful for determining
custom priorities. For example, here's a simple method to use PSQs for
max-queues:

```elixir
iex> q = PSQ.new(&(-&1))
iex> q = [?a, ?b, ?c, ?d, ?e] |> Enum.into(q)
iex> q |> Enum.to_list
[?e, ?d, ?c, ?b, ?a]
```

Here's a queue that orders strings by size, using downcased strings as keys:

```elixir
iex> q = PSQ.new(&String.length/1, &String.downcase/1)
iex> q = ["How", "is", "your", "ocelot"] |> Enum.into(q)
iex> q |> Enum.to_list
["is", "How", "your", "ocelot"]
iex> q |> PSQ.get("how")
"How"
iex> q |> PSQ.get("How")
nil
```

Priority and key mappers are also useful if you're inputting entries that are
structs or maps and want to use particular fields as keys or priorities. For
example:

```elixir
iex> q = PSQ.new(&(&1[:priority]), &(&1[:key]))
iex> q = PSQ.put(q, %{priority: 5, key: 1})
iex> q = PSQ.put(q, %{priority: 2, key: 2})
iex> q = PSQ.put(q, %{priority: 1, key: 1})
iex> q |> PSQ.min
%{priority: 1, key: 1}
iex> q |> PSQ.get(1)
%{priority: 1, key: 1}
```

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
