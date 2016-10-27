require 'rspec'
require 'json'

def last_json
  @response.body
end

Given(/^I post to url "(.*?)" with the entries:$/) do |endpoint, table|
  table.hashes.each do |row|
    @response = HTTP.post(endpoint, row)
  end
end

Given(/^I post to "(.*?)" with the data:$/) do |endpoint, data_string|
  @response = HTTP.post(endpoint, JSON.parse(data_string))
end

Given(/^I successfully post to "(.*?)" with the data:$/) do |endpoint, data_string|
  @response = HTTP.post(endpoint, JSON.parse(data_string))
  expect(@response.status.split.first).to match(/2\d\d/)
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

# http://stackoverflow.com/a/14353011/91144
Then(/^the returned HTTP headers should include:$/) do |table|
  _, *http_headers = @response.header_str.split(/[\r\n]+/).map(&:strip)
  http_headers = Hash[http_headers.flat_map{ |s| s.scan(/^(\S+): (.+)/) }]
  table.hashes.each do |row|
    expect(http_headers).to include(row['header'])
    expect(http_headers[row['header']]).to eq(row['value'])
  end
end
