defmodule PSQTest do
  use ExUnit.Case, async: false
  use ExCheck
  import PSQ

  doctest PSQ

  test "sanity test" do
    q = new_q
    q = q |> insert(3) |> insert(2) |> insert(5) |> insert(1) |> insert(4)

    {{:entry, 5}, q} = q |> pop
    {{:entry, 4}, q} = q |> pop
    {{:entry, 3}, q} = q |> pop
    {{:entry, 2}, q} = q |> pop
    {{:entry, 1}, q} = q |> pop
    {:empty, _} = q |> pop
  end

  property :sort do
    for_all xs in list(int) do
      q = new_q(xs)
      l = to_list(q)

      l == Enum.reverse(Enum.sort(Enum.uniq(xs)))
    end
  end

  property :minimum do
    for_all xs in list(int) do
      q = new_q(xs)
      case pop(q) do
        {{:entry, min}, _} ->
          Enum.all? xs, fn(x) ->
            x <= min
          end
        {:empty, _} -> true
      end
    end
  end

  property :membership do
    for_all xs in list(int) do
      q = new_q(xs)
      Enum.all? xs, fn(x) ->
        lookup(q, x) != nil
      end
    end
  end

  property :deletion do
    for_all xs in list(int) do
      q = new_q(xs)
      Enum.all? xs, fn(x) ->
        lookup(delete(q, x), x) == nil
      end
    end
  end

  defp new_q(xs \\ []) do
    new(xs, priority_fn: &(-&1))
  end
end
