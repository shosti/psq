defmodule PSQ.Entry do
  @moduledoc false
  @type t :: {PSQ.key(), PSQ.value(), PSQ.priority()}

  @spec new(PSQ.value(), PSQ.priority(), PSQ.key()) :: t
  def new(val, priority, key) do
    {key, val, priority}
  end

  @spec key(t) :: PSQ.key()
  def key({k, _, _}), do: k

  @spec value(t) :: PSQ.value()
  def value({_, v, _}), do: v

  @spec priority(t) :: PSQ.priority()
  def priority({_, _, p}), do: p
end
