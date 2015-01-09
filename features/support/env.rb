require 'bundler/setup'

IMAGE="target"

Before do
  @container_id = start_container IMAGE unless @container_id
  sleep 5 # Allow the server to start
end

After do
  stop_container @container_id
end
