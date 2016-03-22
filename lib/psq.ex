defmodule PSQ do
  alias PSQ.Entry

  defstruct xs: []

  def new do
    %PSQ{}
  end

  def new(xs) do
    Enum.into xs, new
  end

  def to_list(q) do
    Enum.into q, []
  end

  def insert(q = %PSQ{xs: xs}, entry) do
    if lookup(q, Entry.key(entry)) do
      q
    else
      %PSQ{xs: [entry | xs]}
    end
  end

  def pop(q = %PSQ{xs: []}) do
    {:empty, q}
  end

  def pop(q = %PSQ{xs: xs}) do
    min_entry = xs |> Enum.min_by(&Entry.priority/1)

    {{:entry, min_entry}, delete(q, Entry.key(min_entry))}
  end

  def lookup(%PSQ{xs: xs}, k) do
    xs |> Enum.find(&(Entry.key(&1) == k))
  end

  def delete(%PSQ{xs: xs}, k) do
    %PSQ{xs: xs |> Enum.reject(&(Entry.key(&1) == k))}
  end
end

defimpl Enumerable, for: PSQ do
  def count(%PSQ{xs: xs}), do: count(xs)
  def member?(%PSQ{xs: xs}, element), do: member?(xs, element)

  def reduce(_,   {:halt, acc}, _fun),           do: {:halted, acc}
  def reduce(q,   {:suspend, acc}, fun),         do: {:suspended, acc, &reduce(q, &1, fun)}
  def reduce(%PSQ {xs: []}, {:cont, acc}, _fun), do: {:done, acc}
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
