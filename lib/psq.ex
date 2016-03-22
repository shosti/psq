defmodule PSQ do
  alias PSQ.Entry

  def empty do
    []
  end

  def insert(q, entry) do
    [entry | q]
  end

  def pop([]) do
    {:empty, []}
  end

  def pop(q) do
    min_entry = q |> Enum.min_by(&Entry.priority/1)

    {{:entry, min_entry}, delete(q, Entry.key(min_entry))}
  end

  def lookup(q, k) do
    q |> Enum.find(&(Entry.key(&1) == k))
  end

  def delete(q, k) do
    q |> Enum.reject(&(Entry.key(&1) == k))
  end
end
