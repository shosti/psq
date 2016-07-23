defmodule PSQTest do
  use ExUnit.Case, async: false
  use ExCheck
  import PSQ
  require Integer

  doctest PSQ

  test "priority_mapper determines the order" do
    priority_mapper = fn x ->
      if Integer.is_even x do
        1
      else
        0
      end
    end

    q = [1,2,3,4] |> Enum.into(new(priority_mapper))

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

  test "key_mapper determines uniqueness and get" do
    elems = [
      %{key: 3, priority: 1},
      %{key: 4, priority: 2},
      %{key: 0, priority: 3},
      %{key: 3, priority: 4},
    ]

    key_mapper = &(&1[:key])
    priority_mapper = &(&1[:priority])
    q = elems |> Enum.into(new(priority_mapper, key_mapper))

    assert Enum.count(q) == 3
    assert %{key: 4, priority: 2} = q |> get(4)
    assert %{key: 0, priority: 3} = q |> get(0)
    assert %{key: 3, priority: 4} = q |> get(3)
    assert {%{key: 4, priority: 2}, _} = q |> pop
  end

  property :sort do
    for_all xs in list(int) do
      q = new_q(xs)
      l = Enum.to_list(q)

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

  property :at_most do
    for_all xs in list(int) do
      q = new_q(xs)
      if Enum.empty?(xs) do
        at_most(q, :rand.uniform(1000)) == []
      else
        pivot = Enum.random(xs)
        subset = at_most(q, pivot)

        Enum.all? xs, fn(x) ->
          if (-x) <= pivot do
            Enum.member?(q, x) && Enum.member?(subset, x)
          else
            Enum.member?(q, x) && !Enum.member?(subset, x)
          end
        end
      end
    end
  end

  property :balanced do
    for_all xs in list(int) do
      q = new_q(xs)
      is_balanced?(q)
    end
  end

  defp is_balanced?(q) do
    case q.tree do
      :void -> true
      winner ->
        loser = winner |> PSQ.Winner.loser
        case loser do
          :start -> true
          _ ->
            left = loser |> PSQ.Loser.left |> PSQ.Loser.size
            right = loser |> PSQ.Loser.right |> PSQ.Loser.size

            (left + right <= 2) || (left <= 4 * right && right <= 4 * left)
        end
    end
  end

  defp new_q(xs) do
    xs |> Enum.into(new(&(-&1)))
  end
end
