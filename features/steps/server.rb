require 'rspec'

When(/^I fetch the file '(.*)'$/) do |file|
  require 'curl'
  url = "http://#{docker_address}:8080/#{file}"
  @response = Curl.get(url)
end
