defmodule PSQ.Loser do
  @type t :: {PSQ.Entry.t, t, PSQ.key, t, non_neg_integer} | :start

  @spec new(PSQ.Entry.t, t, PSQ.key, t) :: t
  def new(entry, left, split_key, right) do
    s = size(left) + size(right) + 1
    {entry, left, split_key, right, s}
  end

  @spec left(t) :: t
  def left({_, l, _, _, _}), do: l

  @spec right(t) :: t
  def right({_, _, _, r, _}), do: r

  @spec size(t) :: non_neg_integer
  def size(:start), do: 0
  def size({_, _, _, _, s}), do: s

  @spec origin(t) :: :left | :right
  def origin({entry, _, split_key, _, _}) do
    key = PSQ.Entry.key(entry)
    cond do
      key > split_key -> :right
      key <= split_key -> :left
    end
  end
end
