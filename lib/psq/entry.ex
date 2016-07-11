defmodule PSQ.Entry do
  defstruct key: nil, value: nil, priority: nil

  @type t :: %__MODULE__{key: PSQ.key, value: PSQ.value, priority: PSQ.priority}
end
