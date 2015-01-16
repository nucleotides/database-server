require 'bundler/setup'

Before do
  # Ensure a clean database at start of features
  $clean ||= false
  unless $clean
    SDB.refresh
    $clean = true
  end
end
