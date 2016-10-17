require 'csv'
require 'json'

def parse_csv(raw_csv)
    CSV.new(raw_csv, :headers => true, :header_converters => :symbol).
      to_a.
      map(&:to_hash).
      reject(&:empty?)
end

Then(/^the returned body should be a valid (CSV|JSON) document$/) do |doc|
  funcs = {
    'CSV'  => lambda {|x| parse_csv(x)},
    'JSON' => lambda {|x| JSON.parse(x)}
  }
  expect{@document = funcs[doc].call(@response.body)}.to_not raise_error
end

Then(/^the returned document should be empty$/) do
  expect(@document).to be_empty
end

Then(/^the returned document should not be empty$/) do
  expect(@document).to_not be_empty
end

Then(/^the returned document should contain (\d+) entries$/) do |n|
  expect(@document.length).to eq(n.to_i), "Document length was not #{n}: \n#{@document}\n\n"
end
