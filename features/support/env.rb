require 'bundler/setup'
require 'rspec'
require 'aruba/cucumber'
require 'json_spec/cucumber'

# Allow `lein trampoline run` to complete
sleep 5

# Testing database migrations can sometimes take a long time
# Might be work reducing the size of the test data in future
Aruba.configure do |config|
  config.exit_timeout = 30
end
