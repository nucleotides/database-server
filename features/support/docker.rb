require 'uri'

def start_container(image)
  container_id = `docker run --publish=8080:8080 --detach=true #{image}`
end

def stop_container(container_id)
  `docker kill #{container_id}`
end

def docker_address
  if ENV['DOCKER_HOST']
    URI.parse(ENV['DOCKER_HOST']).host
  else
    "localhost"
  end
end

