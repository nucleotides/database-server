def contains_row?(hashes, test_hash)
  matching = hashes.select do |hash|
    hash.to_str_values.include_hash? test_hash.to_str_values
  end
  not matching.empty?
end
