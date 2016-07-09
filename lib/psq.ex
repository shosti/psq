defmodule PSQ do
  defstruct xs: [], key: nil, priority: nil

  def new do
    new([], [])
  end

  def new(xs, opts \\ []) do
    key = opts[:key] || &(&1)
    priority = opts[:priority] || &(&1)
    q = %PSQ{key: key, priority: priority}
    Enum.into xs, q
  end

  def to_list(q) do
    Enum.into q, []
  end

  def insert(q = %PSQ{xs: xs, key: key}, entry) do
    if lookup(q, key.(entry)) do
      q
    else
      %PSQ{q | xs: [entry | xs]}
    end
  end

  def pop(q = %PSQ{xs: []}) do
    {:empty, q}
  end

  def pop(q = %PSQ{xs: xs, key: key, priority: priority}) do
    min_entry = xs |> Enum.min_by(priority)

    {{:entry, min_entry}, delete(q, key.(min_entry))}
  end

  def lookup(%PSQ{xs: xs, key: key}, k) do
    xs |> Enum.find(&(key.(&1) == k))
  end

  def delete(q = %PSQ{xs: xs, key: key}, k) do
    %PSQ{q | xs: (xs |> Enum.reject(&(key.(&1) == k)))}
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
