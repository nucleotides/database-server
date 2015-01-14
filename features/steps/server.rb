require 'rspec'
require 'json'

Given(/^I post to url "(.*?)" with the records:$/) do |endpoint, table|
  table.hashes.each do |row|
    HTTP.post(endpoint, row)
  end
end

When(/^I post to url "(.*?)" with the data:$/) do |endpoint, data_string|
  @response = HTTP.post(endpoint, JSON.parse(data_string))
end

When(/^I get the url "(.*?)"$/) do |endpoint|
  sleep 1 #Allow data to be posted
  @response = HTTP.get(endpoint)
end

When(/^I get the url "(.*?)" with the event id$/) do |endpoint|
  sleep 1 #Allow data to be posted
  @response = HTTP.get(endpoint, {id: @response.body.strip})
end

Then(/^the returned HTTP status code should be "(.*?)"$/) do |code|
  expect(@response.status.split.first).to eq(code)
end

Then(/^the returned body should match "(.*?)"$/) do |re|
  expect(@response.body.strip).to match(re)
end

Then(/^the returned body should be a valid JSON document$/) do
  expect{@document = JSON.parse(@response.body)}.to_not raise_error
end

Then(/^the JSON document should contain "(.*?)" entries$/) do |length|
  expect(@document.length).to eq(length.to_i)
end

Then(/^the returned JSON document should match the key-value pairs:$/) do |table|
  table.hashes.each do |row|
    expect(@document.keys).to include(row['key'])
    expect(@document[row['key']]).to match(Regexp.compile(row['value']))
  end
end

Then(/^the returned JSON document should include the key\-value pairs:$/) do |table|
  table.hashes.each do |row|
    expect(@document.keys).to include(row['key'])
    expect(@document[row['key']]).to eq(row['value'])
  end
end

Then(/^the JSON document entry "(.*?)" should include the key\-value pairs$/) do |index, table|
  entry = @document[index.to_i]
  table.hashes.each do |row|
    expect(entry.keys).to include(row['key'])
    expect(entry[row['key']]).to eq(row['value'])
  end
end
