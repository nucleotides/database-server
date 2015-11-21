require 'rspec'
require 'json'

Given(/^I post to url "(.*?)" with the entries:$/) do |endpoint, table|
  table.hashes.each do |row|
    @response = HTTP.post(endpoint, row)
  end
  sleep 1 # Allow data to be posted
end

Given(/^I post to url "(.*?)" with the data:$/) do |endpoint, data_string|
  @response = HTTP.post(endpoint, JSON.parse(data_string))
  sleep 1 # Allow data to be posted
end

When(/^I get the url "(.*?)"$/) do |endpoint|
  @response = HTTP.get(endpoint)
end

When(/^I post the url "(.*?)" with:$/) do |endpoint, table|
  @response = HTTP.post(endpoint, table.hashes.first)
end

Then(/^the returned HTTP status code should be "(.*?)"$/) do |code|
  expect(@response.status.split.first).to eq(code)
end

Then(/^the returned body should equal "(.*?)"$/) do |body|
  expect(@response.body.strip).to eq(body)
end

Then(/^the returned body should match "(.*?)"$/) do |re|
  expect(@response.body.strip).to match(re)
end

Then(/^the returned body should be a valid JSON document$/) do
  expect{@document = JSON.parse(@response.body)}.to_not raise_error
end

Then(/^the returned JSON should contain the entries:$/) do |table|
  table.hashes.each do |row|
    unless contains_row?(@document, row)
      difference = diff(row, @document)
      expected = row.to_str_values.awesome_inspect
      fail("The expected entry not found:\n#{expected}\n\nDiff:\n\n#{difference}")
    end
  end
end

Then(/^the returned JSON should contain:$/) do |table|
  pending # express the regexp above with the code you wish you had
end

Then(/^the returned JSON should be empty$/) do
  expect(@document).to be_empty
end

Then(/^the returned JSON should not be empty$/) do
  expect(@document).to_not be_empty
end
