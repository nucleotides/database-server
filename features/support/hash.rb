class Hash

  def sorted_awesome_inspect
    self.sort.to_h.to_str_values.awesome_inspect
  end

  # http://stackoverflow.com/questions/23136002/
  def include_hash?(hash)
    merge(hash) == self
  end

  def to_str_values
    Hash[self.map{|(k,v)| [k, v.to_s.strip]}]
  end

end

