defmodule PSQ.Entry do
  @type t :: {PSQ.key, PSQ.value, PSQ.priority}

  @spec new(PSQ.value, PSQ.prioritizer, PSQ.key_fun) :: t
  def new(value, prioritizer, key_fun) do
    {key_fun.(value), value, prioritizer.(value)}
  end

  @spec key(t) :: PSQ.key
  def key({k, _, _}), do: k

  @spec value(t) :: PSQ.value
  def value({_, v, _}), do: v

  @spec priority(t) :: PSQ.priority
  def priority({_, _, p}), do: p
end
