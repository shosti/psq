defmodule PSQ do
  @moduledoc """
  PSQ provides a purely-functional implementation of priority search queues. A
  priority search queue is a data structure that efficiently supports both
  associative operations (like those for `Map`) and priority-queue operations
  (akin to heaps in imperative languages). The implementation is based on the
  Haskell
  [PSQueue](https://hackage.haskell.org/package/PSQueue-1.1/docs/Data-PSQueue.html)
  package and the associated paper.

  PSQs can be created from lists in O(n log n) time. Once created, the minimum
  element (`min`) and size (`Enum.count`) can be accessed in O(1) time; most
  other basic operations (including `get`, `pop`, and `push`, and `delete`) are
  in O(log n).

  PSQs implement `Enumerable` and `Collectable`, so all your favorite functions
  from `Enum` and `Stream` should work as expected.

  Each entry in a PSQ has an associated *priority* and *key*. Map-like
  operations, such as `get`, use keys to find the entry; all entries in a PSQ
  are unique by key. Ordered operations, such as `pop` and `Enum.to_list`, use
  priority to determine order (with minimum first). Priorities need not be
  unique by entry; entries with the same priority will be popped in unspecified
  order.

  ## Examples

  There are two primary ways to determine a value's priority and key in a
  queue. The simplest is to start with an empty queue and input values with
  priorities and keys directly, through `put/4`:

    iex> q = PSQ.new |> PSQ.put(:a, "foo", 2) |> PSQ.put(:b, "bar", 1)
    iex> q |> PSQ.get(:a)
    "foo"
    iex> q |> PSQ.min
    "bar"

  Alternatively, you can specify mapper functions to determine key and priority
  for all entries in the queue. This is particularly useful for determining
  custom priorities. For example, here's a simple method to use PSQs for
  max-queues:

    iex> q = PSQ.new(&(-&1))
    iex> q = [?a, ?b, ?c, ?d, ?e] |> Enum.into(q)
    iex> q |> Enum.to_list
    [?e, ?d, ?c, ?b, ?a]

  Here's a queue that orders strings by size, using downcased strings as keys:

    iex> q = PSQ.new(&String.length/1, &String.downcase/1)
    iex> q = ["How", "is", "your", "ocelot"] |> Enum.into(q)
    iex> q |> Enum.to_list
    ["is", "How", "your", "ocelot"]
    iex> q |> PSQ.get("how")
    "How"
    iex> q |> PSQ.get("How")
    nil

  Priority and key mappers are also useful if you're inputting entries that are
  structs or maps and want to use particular fields as keys or priorities. For
  example:

    iex> q = PSQ.new(&(&1[:priority]), &(&1[:key]))
    iex> q = PSQ.put(q, %{priority: 5, key: 1})
    iex> q = PSQ.put(q, %{priority: 2, key: 2})
    iex> q = PSQ.put(q, %{priority: 1, key: 1})
    iex> q |> PSQ.min
    %{priority: 1, key: 1}
    iex> q |> PSQ.get(1)
    %{priority: 1, key: 1}
  """
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

  @doc """
  Returns a new empty PSQ.

  Optional params `priority_mapper` and `key_mapper` are functions to determine
  keys and priorities from values. For example, to create a max-queue of numbers
  instead of a min-queue, pass in `&(-&1)` for `priority_mapper`:

    iex> PSQ.new(&(-&1)) |> PSQ.put(3) |> PSQ.put(5) |> PSQ.put(1) |> Enum.to_list
    [5, 3, 1]

  `key_mapper` is useful if your values are structs where particular fields are
  considered a unique key:

    iex> q = PSQ.new(&(&1[:priority]), &(&1[:key]))
    iex> q = q |> PSQ.put(%{key: 1, priority: 1})
    iex> q = q |> PSQ.put(%{key: 1, priority: 3})
    iex> q |> PSQ.get(1)
    %{key: 1, priority: 3}

  `priority_mapper` and `key_mapper` both default to the identity function.
  """
  @spec new(priority_mapper, key_mapper) :: t
  def new(priority_mapper \\ &(&1), key_mapper \\ &(&1)) do
    %PSQ{key_mapper: key_mapper, priority_mapper: priority_mapper}
  end

  @doc """
  Returns a new PSQ from `list`.

  `priority_mapper` and `key_mapper` behave the same way as for `new`.

  ## Examples

    iex> [2, 5, 4, 1, 3] |> PSQ.from_list |> Enum.to_list
    [1, 2, 3, 4, 5]
  """
  @spec from_list(list(value), priority_mapper, key_mapper) :: t
  def from_list(list, priority_mapper \\ &(&1), key_mapper \\ &(&1)) do
    q = new(priority_mapper, key_mapper)
    list |> Enum.into(q)
  end

  @doc """
  Puts the given `value` into the queue, using `priority_mapper` and
  `key_mapper` to determine uniqueness/order (see `new`).

  If a value with the same key already exits in the queue, it will be replaced
  by the new value.

  ## Examples

    iex> q = PSQ.new(&(&1), &trunc/1)
    iex> q = PSQ.put(q, 3.89)
    iex> q = PSQ.put(q, 2.71)
    iex> q = PSQ.put(q, 3.14)
    iex> Enum.to_list(q)
    [2.71, 3.14]
  """
  @spec put(t, value) :: t
  def put(q = %PSQ{priority_mapper: priority_mapper, key_mapper: key_mapper}, val) do
    put(q, key_mapper.(val), val, priority_mapper.(val))
  end

  @doc """
  Puts the given `value` into the queue with specified `key` and
  `priority`.

  When using this function (as opposed to `put/2`), the queue's
  `priority_mapper` and `key_mapper` will be ignored. It is not recommended to
  use both mappers and direct keys/priorities for the same queue.


  ## Examples

    iex> PSQ.new |> PSQ.put(:a, 1, 1) |> PSQ.put(:a, 2, 1) |> PSQ.get(:a)
    2

    iex> PSQ.new |> PSQ.put(:a, 1, 2) |> PSQ.put(:b, 2, 1) |> Enum.to_list
    [2, 1]
  """
  @spec put(t, key, value, priority) :: t
  def put(q = %PSQ{tree: tree}, key, val, priority) do
    entry = Entry.new(val, priority, key)
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

  @doc """
  Returns and removes the value with the minimum priority from `q`. The value
  will be `nil` if the queue is empty.

  ## Examples

    iex> q = PSQ.from_list([3, 1])
    iex> {min, q} = PSQ.pop(q)
    iex> min
    1
    iex> {min, q} = PSQ.pop(q)
    iex> min
    3
    iex> {min, q} = PSQ.pop(q)
    iex> min
    nil
    iex> Enum.empty?(q)
    true
  """
  @spec pop(t) :: {value, t}
  def pop(q = %PSQ{tree: :void}) do
    {nil, q}
  end

  def pop(q = %PSQ{tree: {entry, loser, max_key}}) do
    new_winner = second_best(loser, max_key)
    {Entry.value(entry), %PSQ{q | tree: new_winner}}
  end

  @doc """
  Returns the value with the minimum priority from `q`.

  Raises `Enum.EmptyError` if the queue is empty.

  ## Examples

    iex> PSQ.from_list([-2, 3, -5]) |> PSQ.min
    -5
    iex> PSQ.from_list([-2, 3, -5], &(-&1)) |> PSQ.min
    3
    iex> PSQ.new |> PSQ.min
    ** (Enum.EmptyError) empty error
  """
  @spec min(t) :: value | no_return
  def min(%PSQ{tree: :void}) do
    raise Enum.EmptyError
  end

  def min(%PSQ{tree: tree}) do
    tree |> Winner.entry |> Entry.value
  end

  @doc """
  Gets the value for specified `key`. If the key does not exist, returns `nil`.


  ## Examples

    iex> PSQ.new |> PSQ.put(:a, 3, 1) |> PSQ.get(:a)
    3
    iex> PSQ.new |> PSQ.put(:a, 3, 1) |> PSQ.get(:b)
    nil
  """
  @spec get(t, key) :: value
  def get(q, key) do
    case fetch(q, key) do
      {:ok, val} -> val
      :error -> nil
    end
  end

  @doc """
  Fetches the value for specified `key` and returns in a tuple. Returns
  `:error` if the key does not exist.

  ## Examples

    iex> PSQ.new |> PSQ.put(:a, 3, 1) |> PSQ.fetch(:a)
    {:ok, 3}
    iex> PSQ.new |> PSQ.put(:a, 3, 1) |> PSQ.fetch(:b)
    :error
  """
  @spec fetch(t, key) :: {:ok, value} | :error
  def fetch(%PSQ{tree: tree}, key) do
    do_fetch(tree, key)
  end

  @doc """
  Fetches the value for specified `key`.

  If `key` does not exist, a `KeyError` is raised.

  ## Examples

    iex> PSQ.new |> PSQ.put(:a, 3, 1) |> PSQ.fetch!(:a)
    3
    iex> PSQ.new |> PSQ.put(:a, 3, 1) |> PSQ.fetch!(:b)
    ** (KeyError) key :b not found in: #PSQ<min:3 size:1>
  """
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

  @doc """
  Deletes the value associated with `key` from `q`.

  If `key` does not exist, returns `q` unchanged.

  ## Examples

    iex> PSQ.from_list([3,1,2]) |> PSQ.delete(2) |> Enum.to_list
    [1, 3]
    iex> PSQ.from_list([3,1,2]) |> PSQ.delete(4) |> Enum.to_list
    [1, 2, 3]
  """
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

  @doc """
  Returns a list of all values from `q` where the value's priority is less than
  or equal to `priority`.

  ## Examples

    iex> PSQ.from_list([1, 3, 2, 5, 4]) |> PSQ.at_most(3)
    [1, 2, 3]
  """
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
      l > (@balance_factor * r) -> balance_right(loser)
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

defimpl Inspect, for: PSQ do
  import Inspect.Algebra

  def inspect(q, opts) do
    case q.tree do
      :void -> "#PSQ<empty>"
      _ ->
        concat ["#PSQ<min:", to_doc(PSQ.min(q), opts), " size:", to_doc(Enum.count(q), opts), ">"]
    end
  end
end
