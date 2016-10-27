Then(/^the returned JSON should contain the entries:$/) do |table|
  table.hashes.each do |row|
    unless contains_row?(@document, row)
      difference = diff(row, @document)
      expected = row.to_str_values.awesome_inspect
      fail("The expected entry should be returned:\n#{expected}\n\nDiff:\n\n#{difference}")
    end
  end
end

Then(/^the returned JSON should not contain the entries:$/) do |table|
  table.hashes.each do |row|
    if contains_row?(@document, row)
      difference = diff(row, @document)
      expected = row.to_str_values.awesome_inspect
      fail("The expected entry should not be returned:\n#{expected}\n\nDiff:\n\n#{difference}")
    end
  end
end

Then(/^the returned JSON should contain:$/) do |table|
  table.hashes.each do |row|
    path = row['key'].split('.')
    value = path.inject(@document) do |acc, key|
      expect(acc).to include(key),
        "Expected key #{row['key']} in: #{@document.awesome_inspect}"
      acc[key]
    end
    expect(value.to_s).to eq(row['value'].to_s),
      "Expected #{row['key']} to equal '#{row['value'].to_s}' but was '#{value.to_s}'"
  end
end
