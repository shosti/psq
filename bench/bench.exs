defmodule PSQBench do
  def q(n) do
    list = Enum.to_list(1..n) |> Enum.map(&(&1 * &1)) |> Enum.shuffle
    PSQ.from_list(list)
  end

  def put(q, n) do
    # We want a probably-new element in the right range, so we square first
    x = :rand.uniform(n * n)
    PSQ.put(q, x)
  end

  def pop(q) do
    PSQ.pop(q)
  end

  def get(q, n) do
    x = :rand.uniform(n)
    PSQ.get(q, x * x)
  end

  def delete(q, n) do
    x = :rand.uniform(n)
    PSQ.delete(q, x * x)
  end

  def at_most(q, _n) do
    max = 50 * 50
    PSQ.at_most(q, max)
  end
end

date = DateTime.utc_now |> DateTime.to_unix
fname = Path.join([System.cwd, "bench", "data", "#{date}.csv"])
file = File.open! fname, [:write]

b = Enum.reduce [100_000, 1_000_000, 10_000_000], Benchee.init, fn (n, b) ->
  IO.puts("Making PSQ of size #{n}...")
  q = PSQBench.q(n)
  IO.puts("Made PSQ!")

  b
  |> Benchee.benchmark("put #{n}", fn -> PSQBench.put(q, n) end)
  |> Benchee.benchmark("pop #{n}", fn -> PSQBench.pop(q) end)
  |> Benchee.benchmark("get #{n}", fn -> PSQBench.get(q, n) end)
  |> Benchee.benchmark("delete #{n}", fn -> PSQBench.delete(q, n) end)
  |> Benchee.benchmark("at_most #{n}", fn -> PSQBench.at_most(q, n) end)
end

b
|> Benchee.measure
|> Benchee.Statistics.statistics
|> Benchee.Formatters.CSV.format
|> Enum.each(fn(row) -> IO.write(file, row) end)

File.close file
