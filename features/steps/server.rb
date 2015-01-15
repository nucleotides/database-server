require 'rspec'
require 'json'

Given(/^I post to url "(.*?)" with the records:$/) do |endpoint, table|
  table.hashes.each do |row|
    @response = HTTP.post(endpoint, row)
  end
end

Given(/^I post to url "(.*?)" with the data:$/) do |endpoint, data_string|
  @response = HTTP.post(endpoint, JSON.parse(data_string))
end

Given(/^I save the last event id$/) do
  @event_id = @response.body
end

When(/^I get the url "(.*?)"$/) do |endpoint|
  sleep 1 #Allow data to be posted
  @response = HTTP.get(endpoint)
end

When(/^I get the url "(.*?)" with the event id$/) do |endpoint|
  sleep 1 #Allow data to be posted
  @response = HTTP.get(endpoint, {id: @response.body.strip})
end

When(/^I lookup the records using the max_id$/) do
  step("I get the url \"/events/lookup.json?max_id=#{@event_id}\"")
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

Then(/^the JSON document should include include the events:$/) do |table|
  table.hashes.each do |row|
    entries = @document.select{|i| i["benchmark_id"] == row['benchmark_id']}
    expect(entries).to_not be_empty
  end
end

Then(/^the JSON document should not include include the events:$/) do |table|
  table.hashes.each do |row|
    entries = @document.select{|i| i["benchmark_id"] == row['benchmark_id']}
    expect(entries).to be_empty
  end
end
