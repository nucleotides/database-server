require 'uri'

def docker_address
  if ENV['DOCKER_HOST']
    URI.parse(ENV['DOCKER_HOST']).host
  else
    "localhost"
  end
end

def docker_url
  "http://#{docker_address}:80"
end
