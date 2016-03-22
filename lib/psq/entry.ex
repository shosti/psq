defprotocol PSQ.Entry do
  @doc "Returns the search key for an entry."
  def key(entry)

  @doc "Returns the priority for an entry (where a lower priority \"wins\")."
  def priority(entry)
end
