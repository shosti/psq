defmodule PSQBench do
  use Benchfella

  @list_100       Enum.to_list(1..100) |> Enum.shuffle
  @list_1_000     Enum.to_list(1..1_000) |> Enum.shuffle
  @list_10_000    Enum.to_list(1..10_000) |> Enum.shuffle

  @q_100 PSQ.new(@list_100)
  @q_1_000 PSQ.new(@list_1_000)
  @q_10_000 PSQ.new(@list_10_000)

  bench "from list 100" do
    PSQ.new(@list_100)
  end

  bench "from list 1_000" do
    PSQ.new(@list_1_000)
  end

  bench "from list 10_000" do
    PSQ.new(@list_10_000)
  end

  bench "to list 100" do
    PSQ.to_list(@q_100)
  end

  bench "to list 1_000" do
    PSQ.to_list(@q_1_000)
  end

  bench "to list 10_000" do
    PSQ.to_list(@q_10_000)
  end

  bench "lookup 100", [x: random_entry(@list_100)] do
    PSQ.lookup(@q_100, x)
  end

  bench "lookup 1_000", [x: random_entry(@list_1_000)] do
    PSQ.lookup(@q_1_000, x)
  end

  bench "lookup 10_000", [x: random_entry(@list_10_000)] do
    PSQ.lookup(@q_10_000, x)
  end

  bench "delete 100", [x: random_entry(@list_100)] do
    PSQ.delete(@q_100, x)
  end

  bench "delete 1_000", [x: random_entry(@list_1_000)] do
    PSQ.delete(@q_1_000, x)
  end

  bench "delete 10_000", [x: random_entry(@list_10_000)] do
    PSQ.delete(@q_10_000, x)
  end

  defp random_entry(list = [i | _]) do
    list |> Enum.at(i - 1)
  end
end
