require 'bundler/setup'

Before do
  SDB.destroy
  SDB.create
end
