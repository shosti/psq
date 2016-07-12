defmodule PSQ do
  defstruct tree: :void, key_fun: nil, prioritizer: nil

  alias PSQ.Winner
  alias PSQ.Loser
  alias PSQ.Entry

  @type key :: any
  @type value :: any
  @type priority :: any
  @type key_fun :: (value -> key)
  @type prioritizer :: (value -> priority)
  @type t :: %__MODULE__{tree: Winner.t, key_fun: key_fun, prioritizer: prioritizer}

  @spec new(prioritizer, key_fun) :: t
  def new(prioritizer \\ &(&1), key_fun \\ &(&1)) do
    %PSQ{key_fun: key_fun, prioritizer: prioritizer}
  end

  @spec to_list(t) :: list(value)
  def to_list(q) do
    Enum.into q, []
  end

  @spec from_list(list(value), prioritizer, key_fun) :: t
  def from_list(list, prioritizer \\ &(&1), key_fun \\ &(&1)) do
    sorted = list |> Enum.sort_by(key_fun)
    tree = Enum.reduce sorted, :void, fn(val, t) ->
      k = key_fun.(val)
      t2 = %Winner{entry: %Entry{value: val, key: k, priority: prioritizer.(val)}, max_key: k}
      play(t, t2)
    end
    %PSQ{prioritizer: prioritizer, key_fun: key_fun, tree: tree}
  end

  @spec put(t, value) :: t
  def put(q = %PSQ{tree: tree, prioritizer: prioritizer, key_fun: key_fun}, val) do
    entry = %Entry{value: val, priority: prioritizer.(val), key: key_fun.(val)}
    %PSQ{q | tree: do_put(tree, entry)}
  end

  @spec do_put(Winner.t, Entry.t) :: Winner.t
  defp do_put(:void, entry), do: %Winner{entry: entry, max_key: entry.key}

  defp do_put(winner = %Winner{loser: :start}, entry) do
    cond do
      winner.entry.key < entry.key ->
        play(winner, %Winner{entry: entry, max_key: entry.key})
      winner.entry.key == entry.key ->
        %Winner{winner | entry: entry}
      winner.entry.key > entry.key ->
        play(%Winner{entry: entry, max_key: entry.key}, winner)
    end
  end

  defp do_put(winner, entry) do
    {t1, t2} = unplay(winner)
    if entry.key <= t1.max_key do
      play(do_put(t1, entry), t2)
    else
      play(t1, do_put(t2, entry))
    end
  end

  @spec pop(t) :: {value, t}
  def pop(q = %PSQ{tree: :void}) do
    {nil, q}
  end

  def pop(q = %PSQ{tree: %Winner{entry: entry, loser: loser, max_key: max_key}}) do
    new_winner = second_best(loser, max_key)
    {entry.value, %PSQ{q | tree: new_winner}}
  end

  @spec min(t) :: value | no_return
  def min(%PSQ{tree: :void}) do
    raise Enum.EmptyError
  end

  def min(%PSQ{tree: %Winner{entry: %Entry{value: value}}}) do
    value
  end

  @spec get(t, key) :: value
  def get(q, key) do
    case fetch(q, key) do
      {:ok, val} -> val
      :error -> nil
    end
  end

  @spec fetch(t, key) :: {:ok, value} | :error
  def fetch(%PSQ{tree: tree}, key) do
    do_fetch(tree, key)
  end

  @spec fetch!(t, key) :: value | no_return
  def fetch!(q, key) do
    case fetch(q, key) do
      {:ok, val} -> val
      :error -> raise KeyError, key: key, term: q
    end
  end

  @spec do_fetch(Winner.t, key) :: {:ok, value} | :error
  defp do_fetch(:void, _), do: :error

  defp do_fetch(%Winner{entry: entry, loser: :start}, key) do
    case entry.key do
      ^key -> {:ok, entry.value}
      _    -> :error
    end
  end

  defp do_fetch(winner, key) do
    {t1, t2} = unplay(winner)
    if key <= t1.max_key do
      do_fetch(t1, key)
    else
      do_fetch(t2, key)
    end
  end

  @spec delete(t, key) :: t
  def delete(q = %PSQ{tree: tree}, key) do
    new_tree = do_delete(tree, key)
    %PSQ{q | tree: new_tree}
  end

  @spec do_delete(Winner.t, key) :: Winner.t
  defp do_delete(:void, _), do: :void
  defp do_delete(winner = %Winner{entry: entry, loser: :start}, key) do
    case entry.key do
      ^key -> :void
      _    -> winner
    end
  end

  defp do_delete(winner, key) do
    {t1, t2} = unplay(winner)
    if key <= t1.max_key do
      play(do_delete(t1, key), t2)
    else
      play(t1, do_delete(t2, key))
    end
  end

  @spec at_most(t, priority) :: list(value)
  def at_most(%PSQ{tree: tree}, priority) do
    do_at_most(tree, priority)
  end

  @spec do_at_most(Winner.t, priority) :: list(value)
  defp do_at_most(:void, _), do: []
  defp do_at_most(
        %Winner{entry: %Entry{priority: priority}},
        max_priority
      ) when priority > max_priority do
    []
  end

  defp do_at_most(%Winner{entry: entry, loser: :start}, _) do
    [entry.value]
  end

  defp do_at_most(winner, max_priority) do
    {t1, t2} = unplay(winner)
    do_at_most(t1, max_priority) ++ do_at_most(t2, max_priority)
  end

  # "Tournament" functions

  @spec play(Winner.t, Winner.t) :: Winner.t
  defp play(:void, t), do: t
  defp play(t, :void), do: t

  defp play(
        %Winner{entry: e1 = %Entry{priority: p1}, loser: l1, max_key: k1},
        %Winner{entry: e2 = %Entry{priority: p2}, loser: l2, max_key: k2}
      ) when k1 < k2 do
    size = Loser.size(l1) + Loser.size(l2) + 1
    if p1 <= p2 do
      loser = balance(%Loser{entry: e2, left: l1, split_key: k1, right: l2, size: size})
      %Winner{entry: e1, loser: loser, max_key: k2}
    else
      loser = balance(%Loser{entry: e1, left: l1, split_key: k1, right: l2, size: size})
      %Winner{entry: e2, loser: loser, max_key: k2}
    end
  end

  @spec unplay(Winner.t) :: {Winner.t, Winner.t}
  defp unplay(%Winner{loser: :start}), do: :void
  defp unplay(
        %Winner{
          entry: winner_entry,
          loser: loser = %Loser{
            entry: loser_entry,
            left: left,
            split_key: split_key,
            right: right,
          },
          max_key: max_key,
        }
      ) do
    {left_entry, right_entry} = case Loser.origin(loser) do
      :right -> {winner_entry, loser_entry}
      :left -> {loser_entry, winner_entry}
    end

    {
      %Winner{entry: left_entry, loser: left, max_key: split_key},
      %Winner{entry: right_entry, loser: right, max_key: max_key},
    }
  end

  @spec second_best(Loser.t, key) :: Winner.t
  defp second_best(:start, _), do: :void
  defp second_best(
        %Loser{entry: entry = %{key: key}, left: left, split_key: split_key, right: right},
        max_key
      ) do
    if key <= split_key do
      play(
        %Winner{entry: entry, loser: left, max_key: split_key},
        second_best(right, max_key)
      )
    else
      play(
        second_best(left, split_key),
        %Winner{entry: entry, loser: right, max_key: max_key}
      )
    end
  end

  # Balancing functions

  @balance_factor 4.0

  @spec balance(Loser.t) :: Loser.t
  defp balance(:start), do: :start

  defp balance(loser = %Loser{left: left, right: right}) do
    l = Loser.size(left)
    r = Loser.size(right)
    cond do
      l + r < 2                 -> loser
      r > (@balance_factor * l) -> balance_left(loser)
      l > (@balance_factor * l) -> balance_right(loser)
      true                      -> loser
    end
  end

  @spec balance_left(Loser.t) :: Loser.t
  defp balance_left(loser = %Loser{right: %Loser{left: rl, right: rr}}) do
    if Loser.size(rl) < Loser.size(rr) do
      single_left(loser)
    else
      double_left(loser)
    end
  end

  @spec balance_right(Loser.t) :: Loser.t
  defp balance_right(loser = %Loser{left: %Loser{left: ll, right: lr}}) do
    if Loser.size(lr) < Loser.size(ll) do
      single_right(loser)
    else
      double_right(loser)
    end
  end

  @spec single_left(Loser.t) :: Loser.t
  defp single_left(
        %Loser{
          entry: e1,
          left: t1,
          split_key: k1,
          right: %Loser{
            entry: e2, left: t2, split_key: k2, right: t3
          }
        }
      ) do
    new_left_size = Loser.size(t1) + Loser.size(t2) + 1
    new_size = new_left_size + Loser.size(t3) + 1
    if e2.key <= k2 && e1.priority <= e2.priority do
      new_left = %Loser{entry: e2, left: t1, split_key: k1, right: t2, size: new_left_size}
      %Loser{entry: e1, left: new_left, split_key: k2, right: t3, size: new_size}
    else
      new_left = %Loser{entry: e1, left: t1, split_key: k1, right: t2, size: new_left_size}
      %Loser{entry: e2, left: new_left, split_key: k2, right: t3, size: new_size}
    end
  end

  @spec single_right(Loser.t) :: Loser.t
  defp single_right(
        %Loser{
          entry: e1,
          left: %Loser{
            entry: e2, left: t1, split_key: k1, right: t2
          },
          split_key: k2,
          right: t3,
        }
      ) do
    new_right_size = Loser.size(t2) + Loser.size(t3) + 1
    new_size = Loser.size(t1) + new_right_size + 1
    if e2.key > k1 && e1.priority <= e2.priority do
      new_right = %Loser{entry: e2, left: t2, split_key: k2, right: t3, size: new_right_size}
      %Loser{entry: e1, left: t1, split_key: k1, right: new_right, size: new_size}
    else
      new_right = %Loser{entry: e1, left: t2, split_key: k2, right: t3, size: new_right_size}
      %Loser{entry: e2, left: t1, split_key: k1, right: new_right, size: new_size}
    end
  end

  @spec double_left(Loser.t) :: Loser.t
  defp double_left(loser = %Loser{right: right}) do
    single_left(%Loser{loser | right: single_right(right)})
  end

  @spec double_right(Loser.t) :: Loser.t
  defp double_right(loser = %Loser{left: left}) do
    single_right(%Loser{loser | left: single_left(left)})
  end
end

defimpl Enumerable, for: PSQ do
  def count(%PSQ{tree: :void}), do: {:ok, 0}
  def count(%PSQ{tree: %PSQ.Winner{loser: loser}}) do
    {:ok, PSQ.Loser.size(loser) + 1}
  end
  def member?(q, element) do
    case PSQ.fetch(q, element) do
      {:ok, _} -> {:ok, true}
      :error -> {:ok, false}
    end
  end

  def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}
  def reduce(q, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(q, &1, fun)}
  def reduce(%PSQ{tree: :void}, {:cont, acc}, _fun), do: {:done, acc}
  def reduce(q, {:cont, acc}, fun) do
    {x, rest} = PSQ.pop(q)
    reduce(rest, fun.(x, acc), fun)
  end
end

defimpl Collectable, for: PSQ do
  def into(original) do
    {original, fn
      q, {:cont, x} -> PSQ.put(q, x)
      q, :done -> q
      _, :halt -> :ok
    end}
  end
end
