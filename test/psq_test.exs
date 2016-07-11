defmodule PSQTest do
  use ExUnit.Case, async: false
  use ExCheck
  import PSQ
  require Integer

  doctest PSQ

  test "pop pops the minimum value by default" do
    q = new |> put(3) |> put(2) |> put(5) |> put(1) |> put(4)

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

  test "key_fun determines uniqueness and get" do
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
    assert %{key: 4, priority: 2} = q |> get(4)
    assert %{key: 0, priority: 3} = q |> get(0)
    assert %{key: 3, priority: 4} = q |> get(3)
    assert {%{key: 4, priority: 2}, _} = q |> pop
  end

  test "fetch returns a tuple" do
    q = from_list([1,2,3])
    assert {:ok, 3} = fetch(q, 3)
    assert :error = fetch(q, 4)
  end

  test "fetch! returns a value or raises an KeyError" do
    q = from_list([1,2,3])
    assert 3 = fetch!(q, 3)
    assert_raise KeyError, fn -> fetch!(q, 4) end
  end

  property :sort do
    for_all xs in list(int) do
      q = new_q(xs)
      l = to_list(q)

      l == Enum.reverse(Enum.sort(Enum.uniq(xs)))
    end
  end

  property :count do
    for_all xs in list(int) do
      q = new_q(xs)

      Enum.count(q) == Enum.count(Enum.uniq(xs))
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
        Enum.member? q, x
      end
    end
  end

  property :deletion do
    for_all xs in list(int) do
      q = new_q(xs)
      Enum.all? xs, fn(x) ->
        !Enum.member?(delete(q, x), x)
      end
    end
  end

  defp new_q(xs) do
    xs |> Enum.into(new(&(-&1)))
  end
end
