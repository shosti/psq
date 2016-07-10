defmodule PSQTest do
  use ExUnit.Case, async: false
  use ExCheck
  import PSQ
  require Integer

  doctest PSQ

  test "pop pops the minimum value by default" do
    q = new |> insert(3) |> insert(2) |> insert(5) |> insert(1) |> insert(4)

    assert {1, q} = q |> pop
    assert {2, q} = q |> pop
    assert {3, q} = q |> pop
    assert {4, q} = q |> pop
    assert {5, q} = q |> pop
    assert {nil, _} = q |> pop
  end

  test "from_list makes a queue from the list" do
    list = [2, 3, 1, 5, 4]
    q = from_list(list)

    assert to_list(q) == [1, 2, 3, 4, 5]
  end

  test "prioritizer determines the order" do
    prioritizer = fn x ->
      if Integer.is_even x do
        1
      else
        0
      end
    end

    q = [1,2,3,4] |> Enum.into(new(prioritizer))

    {x, q} = q |> pop
    assert Integer.is_odd(x)
    {x, q} = q |> pop
    assert Integer.is_odd(x)
    {x, q} = q |> pop
    assert Integer.is_even(x)
    {x, q} = q |> pop
    assert Integer.is_even(x)
    assert {nil, _} = q |> pop
  end

  test "key_fun determines uniqueness and lookup" do
    elems = [
      %{key: 3, priority: 1},
      %{key: 4, priority: 2},
      %{key: 0, priority: 3},
      %{key: 3, priority: 4},
    ]

    key_fun = &(&1[:key])
    prioritizer = &(&1[:priority])
    q = elems |> Enum.into(new(prioritizer, key_fun))

    assert Enum.count(q) == 3
    assert %{key: 4, priority: 2} = q |> lookup(4)
    assert %{key: 0, priority: 3} = q |> lookup(0)
    assert %{key: 3, priority: 4} = q |> lookup(3)
    assert {%{key: 4, priority: 2}, _} = q |> pop
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
        nil -> true
        {min, _} ->
          Enum.all? xs, fn(x) ->
            x <= min
          end
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

  defp new_q(xs) do
    xs |> Enum.into(new(&(-&1)))
  end
end
