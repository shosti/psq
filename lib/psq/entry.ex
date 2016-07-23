defmodule PSQ.Entry do
  @type t :: {PSQ.key, PSQ.value, PSQ.priority}

  @spec new(PSQ.value, PSQ.priority_mapper, PSQ.key_mapper) :: t
  def new(value, priority_mapper, key_mapper) do
    {key_mapper.(value), value, priority_mapper.(value)}
  end

  @spec key(t) :: PSQ.key
  def key({k, _, _}), do: k

  @spec value(t) :: PSQ.value
  def value({_, v, _}), do: v

  @spec priority(t) :: PSQ.priority
  def priority({_, _, p}), do: p
end
