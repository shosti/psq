defmodule PSQ do
  defstruct xs: [], key_fun: nil, prioritizer: nil

  @type key :: any
  @type value :: any
  @type priority :: any
  @type key_fun :: (value -> key)
  @type prioritizer :: (value -> priority)
  @opaque vals :: list(value)
  @type t :: %__MODULE__{xs: vals, key_fun: key_fun, prioritizer: prioritizer}

  @spec new(prioritizer, key_fun) :: t
  def new(prioritizer, key_fun \\ &(&1)) do
    %PSQ{key_fun: key_fun, prioritizer: prioritizer}
  end

  def new do
    new(&(&1), &(&1))
  end

  @spec to_list(t) :: list(value)
  def to_list(q) do
    Enum.into q, []
  end

  @spec insert(t, value) :: t
  def insert(q = %PSQ{key_fun: key_fun}, entry) do
    q = delete(q, key_fun.(entry))
    %PSQ{q | xs: [entry | q.xs]}
  end

  @spec pop(t) :: {value, t}
  def pop(q = %PSQ{xs: []}) do
    {nil, q}
  end

  def pop(q = %PSQ{xs: xs, key_fun: key_fun, prioritizer: prioritizer}) do
    min_entry = xs |> Enum.min_by(prioritizer)

    {min_entry, delete(q, key_fun.(min_entry))}
  end

  @spec lookup(t, key) :: value
  def lookup(%PSQ{xs: xs, key_fun: key_fun}, k) do
    xs |> Enum.find(&(key_fun.(&1) == k))
  end

  @spec delete(t, key) :: t
  def delete(q = %PSQ{xs: xs, key_fun: key_fun}, k) do
    %PSQ{q | xs: (xs |> Enum.reject(&(key_fun.(&1) == k)))}
  end
end

defimpl Enumerable, for: PSQ do
  def count(%PSQ{xs: xs}), do: {:ok, Enum.count(xs)}
  def member?(%PSQ{xs: xs}, element), do: member?(xs, element)

  def reduce(_,   {:halt, acc}, _fun),           do: {:halted, acc}
  def reduce(q,   {:suspend, acc}, fun),         do: {:suspended, acc, &reduce(q, &1, fun)}
  def reduce(%PSQ{xs: []}, {:cont, acc}, _fun),  do: {:done, acc}
  def reduce(q, {:cont, acc}, fun) do
    {x, rest} = PSQ.pop(q)
    reduce(rest, fun.(x, acc), fun)
  end
end

defimpl Collectable, for: PSQ do
  def into(original) do
    {original, fn
      q, {:cont, x} -> PSQ.insert(q, x)
      q, :done -> q
      _, :halt -> :ok
    end}
  end
end
