module HTTP
  require 'curl'

  ALLOW_REQUEST_TO_PROCESS = 0.1

  def self.post(endpoint, params)
    response = Curl.post(docker_url + endpoint, params)
    sleep ALLOW_REQUEST_TO_PROCESS
    response
  end

  def self.get(endpoint, query = {})
    url = docker_url + endpoint
    if not query.empty?
      url = query.inject(url + "?") do |string, (k,v)|
        string + k.to_s + '=' + v.to_s
      end
    end
    Curl.get(url)
  end

end
