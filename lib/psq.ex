defmodule PSQ do
  defstruct xs: [], key_fun: nil, prioritizer: nil

  @type key :: any
  @type value :: any
  @type priority :: any
  @type key_fun :: (value -> key)
  @type prioritizer :: (value -> priority)
  @opaque vals :: list(value)
  @type t :: %__MODULE__{xs: vals, key_fun: key_fun, prioritizer: prioritizer}

  @spec new(prioritizer, key_fun) :: t
  def new(prioritizer \\ &(&1), key_fun \\ &(&1)) do
    %PSQ{key_fun: key_fun, prioritizer: prioritizer}
  end

  @spec to_list(t) :: list(value)
  def to_list(q) do
    Enum.into q, []
  end

  @spec from_list(list(value), prioritizer, key_fun) :: t
  def from_list(list, prioritizer \\ &(&1), key_fun \\ &(&1)) do
    q = new(prioritizer, key_fun)
    # TODO: replace be Enum.into (currently a hack for performance reasons)
    %PSQ{q | xs: list}
  end

  @spec put(t, value) :: t
  def put(q = %PSQ{key_fun: key_fun}, entry) do
    q = delete(q, key_fun.(entry))
    %PSQ{q | xs: [entry | q.xs]}
  end

  @spec pop(t) :: {value, t}
  def pop(q = %PSQ{xs: []}) do
    {nil, q}
  end

  def pop(q = %PSQ{key_fun: key_fun}) do
    min_entry = min(q)

    {min_entry, delete(q, key_fun.(min_entry))}
  end

  @spec min(t) :: value | no_return
  def min(%PSQ{xs: xs, prioritizer: prioritizer}) do
    xs |> Enum.min_by(prioritizer)
  end

  @spec get(t, key) :: value
  def get(%PSQ{xs: xs, key_fun: key_fun}, key) do
    xs |> Enum.find(&(key_fun.(&1) == key))
  end

  @spec fetch(t, key) :: {:ok, value} | :error
  def fetch(q, key) do
    case get(q, key) do
      nil -> :error
      val -> {:ok, val}
    end
  end

  @spec fetch!(t, key) :: value | no_return
  def fetch!(q, key) do
    case fetch(q, key) do
      {:ok, val} -> val
      :error -> raise KeyError, key: key, term: q
    end
  end

  @spec delete(t, key) :: t
  def delete(q = %PSQ{xs: xs, key_fun: key_fun}, k) do
    %PSQ{q | xs: (xs |> Enum.reject(&(key_fun.(&1) == k)))}
  end
end

defimpl Enumerable, for: PSQ do
  def count(_q), do: {:error, __MODULE__}
  def member?(q, element) do
    case PSQ.fetch(q, element) do
      {:ok, _} -> {:ok, true}
      :error -> {:ok, false}
    end
  end

  def reduce(_,   {:halt, acc}, _fun),           do: {:halted, acc}
  def reduce(q,   {:suspend, acc}, fun),         do: {:suspended, acc, &reduce(q, &1, fun)}
  def reduce(%PSQ{xs: []}, {:cont, acc}, _fun),  do: {:done, acc}
  def reduce(q, {:cont, acc}, fun) do
    {x, rest} = PSQ.pop(q)
    reduce(rest, fun.(x, acc), fun)
  end
end

defimpl Collectable, for: PSQ do
  def into(original) do
    {original, fn
      q, {:cont, x} -> PSQ.put(q, x)
      q, :done -> q
      _, :halt -> :ok
    end}
  end
end
