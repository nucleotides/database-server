require 'rspec'

When(/^I post to url "(.*?)" with the data:$/) do |endpoint, data_string|
  require 'curl'
  @response = Curl.post(docker_url + endpoint)
end

Then(/^the returned HTTP status code should be "(.*?)"$/) do |code|
  expect(@response.status.split.first).to eq(code)
end
