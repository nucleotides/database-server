module HTTP
  require 'curl'

  def self.post(endpoint, params)
    Curl.post(docker_url + endpoint, params)
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
