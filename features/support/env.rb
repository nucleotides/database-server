require 'bundler/setup'
require 'rspec'
require 'aruba'

# Allow `lein trampoline run` to complete
sleep 5

Before do
  # Ensure a clean database at start of features
  $clean ||= false
  unless $clean
    SDB.refresh
    $clean = true
  end
end
