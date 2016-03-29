defmodule PSQ do
  alias PSQ.Entry

  defstruct xs: [], key_fn: nil, priority_fn: nil

  def new do
    new([], [])
  end

  def new(xs, opts \\ []) do
    key_fn = opts[:key_fn] || &Entry.key/1
    priority_fn = opts[:priority_fn] || &Entry.priority/1
    q = %PSQ{key_fn: key_fn, priority_fn: priority_fn}
    Enum.into xs, q
  end

  def to_list(q) do
    Enum.into q, []
  end

  def insert(q = %PSQ{xs: xs, key_fn: key_fn}, entry) do
    if lookup(q, key_fn.(entry)) do
      q
    else
      %PSQ{q | xs: [entry | xs]}
    end
  end

  def pop(q = %PSQ{xs: []}) do
    {:empty, q}
  end

  def pop(q = %PSQ{xs: xs, key_fn: key_fn, priority_fn: priority_fn}) do
    min_entry = xs |> Enum.min_by(priority_fn)

    {{:entry, min_entry}, delete(q, key_fn.(min_entry))}
  end

  def lookup(%PSQ{xs: xs, key_fn: key_fn}, k) do
    xs |> Enum.find(&(key_fn.(&1) == k))
  end

  def delete(q = %PSQ{xs: xs, key_fn: key_fn}, k) do
    %PSQ{q | xs: (xs |> Enum.reject(&(key_fn.(&1) == k)))}
  end
end

defimpl Enumerable, for: PSQ do
  def count(%PSQ{xs: xs}), do: count(xs)
  def member?(%PSQ{xs: xs}, element), do: member?(xs, element)

  def reduce(_,   {:halt, acc}, _fun),           do: {:halted, acc}
  def reduce(q,   {:suspend, acc}, fun),         do: {:suspended, acc, &reduce(q, &1, fun)}
  def reduce(%PSQ{xs: []}, {:cont, acc}, _fun),  do: {:done, acc}
  def reduce(q, {:cont, acc}, fun) do
    {{:entry, x}, rest} = PSQ.pop(q)
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
