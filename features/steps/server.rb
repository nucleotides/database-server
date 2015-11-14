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

Then(/^the returned HTTP status code should be "(.*?)"$/) do |code|
  expect(@response.status.split.first).to eq(code)
end

Then(/^the returned body should match "(.*?)"$/) do |re|
  expect(@response.body.strip).to match(re)
end

Then(/^the returned body should be a valid JSON document$/) do
  expect{@document = JSON.parse(@response.body)}.to_not raise_error
end

Then(/^the returned JSON should contain the entries:$/) do |table|
  pending # express the regexp above with the code you wish you had
end

Then(/^the returned JSON should not contain any entries$/) do
  expect(@document.length).to eq(0)
end
