defmodule PSQ.Loser do
  defstruct entry: nil, left: :start, split_key: nil, right: :start, size: 1

  @type t :: %__MODULE__{entry: PSQ.Entry.t, left: t, split_key: PSQ.key, right: t, size: non_neg_integer} | :start

  @spec origin(t) :: :left | :right
  def origin(%PSQ.Loser{entry: %PSQ.Entry{key: key}, split_key: split_key}) do
    cond do
      key > split_key -> :right
      key <= split_key -> :left
    end
  end

  @spec size(t) :: non_neg_integer
  def size(:start), do: 0
  def size(%PSQ.Loser{size: size}), do: size
end
