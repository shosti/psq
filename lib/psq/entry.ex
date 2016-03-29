defprotocol PSQ.Entry do
  @fallback_to_any true

  @doc "Returns the search key for an entry."
  def key(entry)

  @doc "Returns the priority for an entry (where a lower priority \"wins\")."
  def priority(entry)
end

defimpl PSQ.Entry, for: Any do
  def key(entry), do: entry
  def priority(entry), do: entry
end
