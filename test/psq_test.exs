defmodule PSQTest do
  use ExUnit.Case, async: false
  use ExCheck
  import PSQ

  doctest PSQ

  defimpl PSQ.Entry, for: Integer do
    def priority(x), do: x
    def key(x), do: x
  end

  test "sanity test" do
    q = empty

    q = q |> insert(3) |> insert(2) |> insert(5) |> insert(1) |> insert(4)

    {{:entry, 1}, q} = q |> pop
    {{:entry, 2}, q} = q |> pop
    {{:entry, 3}, q} = q |> pop
    {{:entry, 4}, q} = q |> pop
    {{:entry, 5}, q} = q |> pop
    {:empty, _} = q |> pop
  end
end
