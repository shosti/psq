defmodule PSQ do
  defstruct tree: :void, key_mapper: nil, priority_mapper: nil

  alias PSQ.Winner
  alias PSQ.Loser
  alias PSQ.Entry

  @type key :: any
  @type value :: any
  @type priority :: any
  @type key_mapper :: (value -> key)
  @type priority_mapper :: (value -> priority)
  @type t :: %__MODULE__{tree: Winner.t, key_mapper: key_mapper, priority_mapper: priority_mapper}

  @spec new(priority_mapper, key_mapper) :: t
  def new(priority_mapper \\ &(&1), key_mapper \\ &(&1)) do
    %PSQ{key_mapper: key_mapper, priority_mapper: priority_mapper}
  end

  @spec to_list(t) :: list(value)
  def to_list(q) do
    Enum.into q, []
  end

  @spec from_list(list(value), priority_mapper, key_mapper) :: t
  def from_list(list, priority_mapper \\ &(&1), key_mapper \\ &(&1)) do
    q = new(priority_mapper, key_mapper)
    list |> Enum.into(q)
  end

  @spec put(t, value) :: t
  def put(q = %PSQ{tree: tree, priority_mapper: priority_mapper, key_mapper: key_mapper}, val) do
    entry = Entry.new(val, priority_mapper, key_mapper)
    %PSQ{q | tree: do_put(tree, entry)}
  end

  @spec do_put(Winner.t, Entry.t) :: Winner.t
  defp do_put(:void, entry), do: Winner.new(entry, :start, Entry.key(entry))

  defp do_put(winner = {winner_entry, :start, max_key}, entry) do
    winner_key = Entry.key(winner_entry)
    entry_key = Entry.key(entry)
    cond do
      winner_key < entry_key ->
        play(winner, Winner.new(entry, :start, entry_key))
      winner_key == entry_key ->
        Winner.new(entry, :start, max_key)
      winner_key > entry_key ->
        play(Winner.new(entry, :start, entry_key), winner)
    end
  end

  defp do_put(winner, entry) do
    {t1, t2} = unplay(winner)
    if Entry.key(entry) <= Winner.max_key(t1) do
      play(do_put(t1, entry), t2)
    else
      play(t1, do_put(t2, entry))
    end
  end

  @spec pop(t) :: {value, t}
  def pop(q = %PSQ{tree: :void}) do
    {nil, q}
  end

  def pop(q = %PSQ{tree: {entry, loser, max_key}}) do
    new_winner = second_best(loser, max_key)
    {Entry.value(entry), %PSQ{q | tree: new_winner}}
  end

  @spec min(t) :: value | no_return
  def min(%PSQ{tree: :void}) do
    raise Enum.EmptyError
  end

  def min(%PSQ{tree: tree}) do
    tree |> Winner.entry |> Entry.value
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

  defp do_fetch({entry, :start, _}, key) do
    case Entry.key(entry) do
      ^key -> {:ok, Entry.value(entry)}
      _    -> :error
    end
  end

  defp do_fetch(winner, key) do
    {t1, t2} = unplay(winner)
    if key <= Winner.max_key(t1) do
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
  defp do_delete(winner = {entry, :start, _}, key) do
    case Entry.key(entry) do
      ^key -> :void
      _    -> winner
    end
  end

  defp do_delete(winner, key) do
    {t1, t2} = unplay(winner)
    if key <= Winner.max_key(t1) do
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
  defp do_at_most({{_, _, priority}, _, _}, max_priority) when priority > max_priority do
    []
  end

  defp do_at_most({entry, :start, _}, _) do
    [Entry.value(entry)]
  end

  defp do_at_most(winner, max_priority) do
    {t1, t2} = unplay(winner)
    do_at_most(t1, max_priority) ++ do_at_most(t2, max_priority)
  end

  # "Tournament" functions

  @spec play(Winner.t, Winner.t) :: Winner.t
  defp play(:void, t), do: t
  defp play(t, :void), do: t

  defp play({e1, l1, k1}, {e2, l2, k2}) when k1 < k2 do
    p1 = Entry.priority(e1)
    p2 = Entry.priority(e2)
    if p1 <= p2 do
      loser = Loser.new(e2, l1, k1, l2) |> balance
      Winner.new(e1, loser, k2)
    else
      loser = Loser.new(e1, l1, k1, l2) |> balance
      Winner.new(e2, loser, k2)
    end
  end

  @spec unplay(Winner.t) :: {Winner.t, Winner.t}
  defp unplay({winner_entry, loser = {loser_entry, left, split_key, right, _}, max_key}) do
    {left_entry, right_entry} = case Loser.origin(loser) do
      :right -> {winner_entry, loser_entry}
      :left  -> {loser_entry, winner_entry}
    end

    {
      Winner.new(left_entry, left, split_key),
      Winner.new(right_entry, right, max_key),
    }
  end

  @spec second_best(Loser.t, key) :: Winner.t
  defp second_best(:start, _), do: :void
  defp second_best({entry, left, split_key, right, _}, max_key) do
    key = Entry.key(entry)
    if key <= split_key do
      play(
        Winner.new(entry, left, split_key),
        second_best(right, max_key)
      )
    else
      play(
        second_best(left, split_key),
        Winner.new(entry, right, max_key)
      )
    end
  end

  # Balancing functions

  @balance_factor 4.0

  @spec balance(Loser.t) :: Loser.t
  defp balance(:start), do: :start

  defp balance(loser = {_, left, _, right, _}) do
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
  defp balance_left(loser) do
    right = Loser.right(loser)
    rl = Loser.left(right)
    rr = Loser.right(right)
    if Loser.size(rl) < Loser.size(rr) do
      single_left(loser)
    else
      double_left(loser)
    end
  end

  @spec balance_right(Loser.t) :: Loser.t
  defp balance_right(loser) do
    left = Loser.left(loser)
    ll = Loser.left(left)
    lr = Loser.right(left)
    if Loser.size(lr) < Loser.size(ll) do
      single_right(loser)
    else
      double_right(loser)
    end
  end

  @spec single_left(Loser.t) :: Loser.t
  defp single_left(loser) do
    {e1, t1, k1, right, _} = loser
    {e2, t2, k2, t3, _} = right
    if Entry.key(e2) <= k2 && Entry.priority(e1) <= Entry.priority(e2) do
      new_left = Loser.new(e2, t1, k1, t2)
      Loser.new(e1, new_left, k2, t3)
    else
      new_left = Loser.new(e1, t1, k1, t2)
      Loser.new(e2, new_left, k2, t3)
    end
  end

  @spec single_right(Loser.t) :: Loser.t
  defp single_right(loser) do
    {e1, left, k2, t3, _} = loser
    {e2, t1, k1, t2, _} = left
    if Entry.key(e2) > k1 && Entry.priority(e1) <= Entry.priority(e2) do
      new_right = Loser.new(e2, t2, k2, t3)
      Loser.new(e1, t1, k1, new_right)
    else
      new_right = Loser.new(e1, t2, k2, t3)
      Loser.new(e2, t1, k1, new_right)
    end
  end

  @spec double_left(Loser.t) :: Loser.t
  defp double_left({entry, left, split_key, right, _}) do
    single_left(Loser.new(entry, left, split_key, single_right(right)))
  end

  @spec double_right(Loser.t) :: Loser.t
  defp double_right({entry, left, split_key, right, _}) do
    single_right(Loser.new(entry, single_left(left), split_key, right))
  end
end

defimpl Enumerable, for: PSQ do
  def count(%PSQ{tree: :void}), do: {:ok, 0}
  def count(%PSQ{tree: winner}) do
    loser = PSQ.Winner.loser(winner)
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
