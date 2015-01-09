require 'rspec'
require 'json'

When(/^I post to url "(.*?)" with the data:$/) do |endpoint, data_string|
  require 'curl'
  data = JSON.parse(data_string)
  @response = Curl.post(docker_url + endpoint, data)
end

When(/^I get the url "(.*?)" with the event id$/) do |endpoint|
  @event_id = @response.body.strip
  url = "#{docker_url}#{endpoint}?id=#{@event_id}"
  @response = Curl.get(url)
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

Then(/^the returned JSON document should include the keys:$/) do |table|
  table.each do |row|
    expect(@document).to include?(table['key'])
  end
end

Then(/^the returned JSON document should include the key\-value pairs:$/) do |table|
  table.each do |row|
    expect(@document).to include?(table['key'])
    expect(@document[table['key']]).to eq(table['value'])
  end
end
