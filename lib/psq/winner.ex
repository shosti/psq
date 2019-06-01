defmodule PSQ.Winner do
  @moduledoc false
  @type t :: {PSQ.Entry.t(), PSQ.Loser.t(), PSQ.key()} | :void

  @spec new(PSQ.Entry.t(), PSQ.Loser.t(), PSQ.key()) :: t
  def new(entry, loser, key) do
    {entry, loser, key}
  end

  @spec entry(t) :: PSQ.Entry.t()
  def entry({e, _, _}), do: e

  @spec loser(t) :: PSQ.Loser.t()
  def loser({_, l, _}), do: l

  @spec max_key(t) :: PSQ.key()
  def max_key({_, _, k}), do: k
end
