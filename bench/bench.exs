defmodule PSQBench do
  def q(n) do
    list = Enum.to_list(1..n) |> Enum.map(&(&1 * &1)) |> Enum.shuffle
    PSQ.from_list(list)
  end

  def insert(q, n) do
    # We want a probably-new element in the right range, so we square first
    x = :rand.uniform(n * n)
    PSQ.insert(q, x)
  end

  def pop(q) do
    PSQ.pop(q)
  end

  def lookup(q, n) do
    x = :rand.uniform(n)
    PSQ.lookup(q, x * x)
  end

  def delete(q, n) do
    x = :rand.uniform(n)
    PSQ.delete(q, x * x)
  end
end

{out, 0} = System.cmd "git", ~w(rev-parse HEAD)
rev = String.strip(out) |> String.slice(0..6)
date = DateTime.utc_now |> DateTime.to_unix
fname = Path.join([System.cwd, "bench", "data", "#{date}-#{rev}.csv"])
file = File.open! fname, [:write]
b = Enum.reduce [10_000, 100_000, 1_000_000], Benchee.init, fn (n, b) ->
  q = PSQBench.q(n)

  b
  |> Benchee.benchmark("insert #{n}", fn -> PSQBench.insert(q, n) end)
  |> Benchee.benchmark("pop #{n}", fn -> PSQBench.pop(q) end)
  |> Benchee.benchmark("lookup #{n}", fn -> PSQBench.lookup(q, n) end)
  |> Benchee.benchmark("delete #{n}", fn -> PSQBench.delete(q, n) end)
end

b
|> Benchee.measure
|> Benchee.Statistics.statistics
|> Benchee.Formatters.CSV.format
|> Enum.each(fn(row) -> IO.write(file, row) end)

File.close file
