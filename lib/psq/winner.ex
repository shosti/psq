defmodule PSQ.Winner do
  defstruct entry: nil, loser: :start, max_key: nil

  @type t :: %__MODULE__{entry: PSQ.Entry.t, loser: PSQ.Loser.t, max_key: PSQ.key} | :void
end
